#!/usr/bin/bash

green='\033[0;32m'
red='\033[0;31m'
gray='\033[1;30m'
yellow='\033[0;33m'
nc='\033[0m'


threads=8
mlen=0
paired=0
method="mean"
factor=0.6

help() {
cont=$(cat << EOF
    ${green}Usage:${nc}
        ${green}$0${nc} <output> <input> [options]


    ${yellow}Description:${nc}
        Filter and process sequencing reads, with optional automatic length filtering.

    ${yellow}Required:${nc}
        <output>              Output path (file or directory)
        <input>               Input fastq file(s) or directory


    ${yellow}Options:${nc}
        -p, --threads <int>       Number of parallel threads (default: ${green}${threads}${nc})
        -l, --min-length <num>    Minimum length threshold to keep a read.
                                Set to 0 for automatic detection (recommended)
                                Default: ${green}0${nc} (auto mode)
        -m, --method <str>        Statistic for auto threshold when --min-length=0
                                Options: mean | median | q1 | q3 | min | max
                                Default: ${green}${method}${nc}
        -f, --factor <float>      Scaling factor for auto threshold (default: ${green}${factor}${nc})
                                Example: mean × 0.8 = 80% of mean length
        -h, --help                Display this help and exit


    ${yellow}Auto mode behavior (--min-length=0):${nc}
        - Samples first ~10,000 reads
        - Computes length statistics (min, max, mean, median, Q1, Q3)
        - Sets filtering threshold = chosen statistic × factor


    ${yellow}Examples:${nc}
        # Auto filter using mean × 0.8, 8 threads
        ${green}$0${nc} outprefix input.fq.gz -p 8

        # Use median × 0.75 as cutoff
        ${green}$0${nc} outprefix input*.fq.gz -l 0 -m median -f 0.75

        # Force keep reads ≥ 100 bp
        ${green}$0${nc} outprefix input.fq.gz -l 100


EOF
)
echo -e "\n\n$cont\n\n"
}

if [ $# -lt 2 ];then
    help
    exit 0
fi

positional=()
while [[ $# -gt 0 ]];do
    case $1 in
        -l|--min_length)
            mlen=$2
            shift 2
            ;;
        -p|--threads)
            threads=$2
            shift 2
            ;;
        -f|--factor)
            factor=$2
            shift 2
            ;;
        -m|--method)
            method=$2
            shift 2
            ;;
        --)
            positional+=("$@")
            break
            ;;
        -*|--*)
            echo "Unknown params $1"
            exit 1
            ;;
        *)
            positional+=("$1")
            shift
            ;;
    esac
done

set -- "${positional[@]}"
set -euo pipefail

out=$(realpath -s $1)
fq1=$(realpath -s $2)

[ ! -f ${fq1} ] && { echo "No such file: $fq1"; exit 127; }

if [ $# -eq 3 ];then
    paired=1
    fq2=$(realpath -s $3)
    [ ! -f ${fq2} ] && { echo "No such file: $fq2"; exit 127; }
fi

if [ $mlen -eq 0 ];then
    stat=$(zcat "$fq1" | head -n 40000 | awk '(NR%4 ==2 ){print length($0)}'  | sort -n  | awk '{ a[NR]=$1; sum +=$1 }END{ if(NR%2==1){ q2=a[(NR+1)/2] }else{ q2=(a[NR/2]+a[NR/2+1])/2}; printf "%f\t%f\t%f\t%f\t%f\t%f\n", a[1], a[NR], sum/NR, q2, a[int (NR*0.25)+1], a[int(NR*0.75)+1] }') || true
    read -r minlen maxlen meanlen medianlen q1 q3 <<< "$stat"
    case "${method,,}" in
        mean)   stat_val="$meanlen" ;;
        median) stat_val="$medianlen" ;;
        q1)     stat_val="$q1" ;;
        q3)     stat_val="$q2" ;;
        min)    stat_val="$minlen" ;;
        max)    stat_val="$maxlen" ;;
        *)
    esac
    threshold=$(printf "%.0f" "$stat_val")
    mlen=$(awk -v factor="$factor" -v threshold="$threshold" 'BEGIN {print int(threshold * factor + 0.5)}')
fi

exec > >(tee ${out}.run.log) 2> >(tee ${out}.run.err >&2)

echo -e "$method:\t$minlen"
echo -e "factor:\t$factor"
echo -e "minlen:\t$mlen"

base_cmd="fastp  -w ${threads} -q 20 -u 30 -n 5 -y -Y 30  --trim_poly_g --trim_poly_x -j /dev/null -h /dev/null -l $mlen "

if [ $paired == 1 ];then
    echo -e "mode:\tpaired"
    echo -e "input:\t$fq1\t${fq2}"
    cmd="$base_cmd -i $fq1 -I $fq2 -o ${out}.1.fq.gz -O ${out}.2.fq.gz"
    echo $cmd | sh
else
    echo -e "mode:\tsingle"
    echo -e "input:\t$fq1"
    cmd="$base_cmd -i $fq1 -o ${out}.fq.gz"
    echo $cmd | sh
fi

echo -e "output:\t$out"

perl -e 'open I, "$ARGV[0]";while(<I>){chomp;if($_=~/^Read1 before filtering:/){$stat=1;next};if($stat==1){$_=~/total reads: (\d+)/;$r1=$1;$stat=0; next};if($_=~/^Read1 after filtering:/){$stat=2;next}; if($stat==2){$_=~/total reads: (\d+)/;$r1a=$1; $rate=$r1a/$r1*100;print "$ARGV[0]\t$r1\t$r1a\t$rate\n";last} }'  $out.log
# print <before: total_reads> <after: total_reads> <rate> <after: q20> <after: q30>
# perl -e 'open I, "$ARGV[0]";while(<I>){chomp;if($_=~/^Read1 before filtering:/){$stat=1;next};if($stat==1){if($_=~/total reads: (\d+)/){$r1=$1};if($_=~/Q20 bases: \d+\((.*)\)/){$q20=$1};if($_=~/Q30 bases: \d+\((.*)\)/){ $q30=$1;$stat=0; next}};if($_=~/^Read1 after filtering:/){$stat=2;next}; if($stat==2){if($_=~/total reads: (\d+)/){$r1a=$1; $rate=$r1a/$r1*100}elsif($_=~/Q20 bases: \d+\((.*)\)/){$q20a=$1;next}elsif($_=~/Q30 bases: \d+\((.*)\)/){$q30a=$1;print "$ARGV[0]\t$r1\t$r1a\t$rate\t$q20a\t$q30a\n";last} }}' $out.log
