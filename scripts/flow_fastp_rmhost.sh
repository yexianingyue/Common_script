#!/usr/bin/bash

set -e

if [ $# -lt 5 ];then
    echo "$0 <fq1> <fq2> <index> <out_prefix> <min_len>"
    echo "min_len: remove length less than <min_len>; 150 -> 90; 100bp -> 60"
    echo -e "Please make sure to run this script using \033[31mbash instead of sh..\033[0m"
    exit 0
fi

fq1=$1
fq2=$2
index=$3
out=$4
len=$5

if [ -f $out.clean_nohost.1.fq.gz ] && [ -f $out.clean_nohost.2.fq.gz ];then
    echo "The file already exists, checking integrity. $out.clean_nohost.1.fq.gz $out.clean_nohost.2.fq.gz"
    pigz -t $out.clean_nohost.1.fq.gz $out.clean_nohost.2.fq.gz && echo "Done" && exit 0;
    echo "file is incomplete."
fi

echo "run fastp"
if [ ! -f $out.fastp.log ] || [[ `grep ', time used: ' $out.fastp.log| wc -l` -ne 1 ]];then
    fastp  -w 10 -q 20 -u 30 -n 5 -y -Y 30  --trim_poly_g --trim_poly_x -j /dev/null -h /dev/null \
        -l $len \
        -o $out.1.fq.gz \
        -i $fq1 -I $fq2 \
        -O $out.2.fq.gz  2> $out.fastp.log \
        || ! echo "ERROR" || exit 127
fi


echo "run bowtie2"
if [ ! -f $out.nohost.log ] || [[ `grep '% overall alignment rate' $out.nohost.log | wc -l` -ne 1 ]];then
    bowtie2 --end-to-end --mm --fast -1 $out.1.fq.gz -2 $out.2.fq.gz  -x $index  --no-head -S $out.sam -p 12 2> $out.nohost.log \
        && rm $out.1.fq.gz $out.2.fq.gz -f || ! echo "ERROR" || exit 127
fi

echo "extract fastq from sam"
less $out.sam | perl -ne 'chomp;@s=split /\s+/;if($s[1]==77){print "\@$s[0]/1\n$s[9]\n+\n$s[10]\n";}elsif($s[1]==141){print STDERR "\@$s[0]/2\n$s[9]\n+\n$s[10]\n";}' \
    > >(pigz > $out.clean_nohost.1.fq.gz) 2> >(pigz > $out.clean_nohost.2.fq.gz) \
    && rm $out.sam -f || ! echo "ERROR" || exit 127

