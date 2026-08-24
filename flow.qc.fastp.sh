#!/usr/bin/env bash
set -euo pipefail

green='\033[0;32m'
red='\033[0;31m'
gray='\033[1;30m'
yellow='\033[0;33m'
nc='\033[0m'


threads=8
mlen=0
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
                                Example: mean × 0.6 = 60% of mean length
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
out=$(realpath -s $1)
fq1=$(realpath -s $2)
finished=0
paired=0

[ ! -f ${fq1} ] && { echo "No such file: $fq1"; exit 127; }

if [ $# -eq 3 ];then
    paired=1
    fq2=$(realpath -s $3)
    [ ! -f ${fq2} ] && { echo "No such file: $fq2"; exit 127; }
fi


tmplock_file="${out}.tmplock"
ok_file="${out}.ok"
error_file="${out}.error"
run_log="${out}.run.log"


logging(){
    local msg=$1
    local file=$2
    echo -e "[$(date '+%Y-%m-%d %H:%M:%S')] ${msg}" >> ${file}
}

run_check(){
    [[ -f "$tmplock_file" ]] && { echo "running."; exit 127; }

    rm -f "$error_file" "$ok_file" 2> /dev/null
    touch "$tmplock_file" 2>/dev/null || { echo -e "can't touch file $tmplock_file" >&2; exit 1; }
}

run_error() {
    local msg="$1"
    rm -f "$tmplock_file" 2>/dev/null
    logging "ERROR: $msg" "$error_file"
    logging "ERROR: $msg" "$run_log"
    echo -e "${red}$msg${nc}" >&2
    exit 1
}

run_end(){
    rm -f "$tmplock_file" 2> /dev/null       # 删除中间文件
    touch "$ok_file"  2> /dev/null              # 创建 ok 文件
    logging "Script finished successfully" "$run_log"
    finished=1
}


run_start(){
    run_check
    # 初始化 run.log
    > "${run_log}"
    logging "Script started" "${run_log}"
    logging "Input: $fq1 ${fq2:+and $fq2}" "${run_log}"
    echo "" >> "$run_log"
}


run_start

run_trap(){
    rm -f "$tmplock_file" 2>/dev/null;
    if (( ! finished )); then
        logging "Script interrupted by signal" "$run_log"
    fi
}


trap run_trap EXIT INT TERM

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

logging "method:\t$method" "$run_log"
logging "facto\t$factor" "$run_log"
logging "minlen:\t$mlen" "$run_log"

base_cmd=(fastp  -w "${threads}" -q 20 -u 30 -n 5 -y -Y 30  --trim_poly_g --trim_poly_x -j /dev/null -h /dev/null -l "$mlen")

if [ $paired == 1 ];then
    logging "mode:\tpaired" "$run_log"
    "${base_cmd[@]}" \
        -i $fq1 -I $fq2 \
        -o ${out}.1.fq.gz -O ${out}.2.fq.gz || run_error "run fastp"
    logging "output:\t${out}.1.fq.gz ${out}.2.fq.gz" "$run_log"
else
    logging "mode:\tsingle" "$run_log"
    logging "input:\t$fq1" "$run_log"
    "${base_cmd[@]}" \
        -i $fq1 \
        -o ${out}.fq.gz || run_error "run fastp"
    logging "output:\t${out}.1.fq.gz" "$run_log"
fi

run_end
