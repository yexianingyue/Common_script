#!/usr/bin/bash

if [ "$#" -ne "4" ]; then
      echo -e "\nusage: sh $0 <index> <fq1> <fq2> <out>\n" 
      exit 2
fi
index=$1
fq1=$2
fq2=$3
out=$4
/usr/bin/time -f "$out time: %U" -a -o bwa.time.log \
    bwa-mem2 mem -t 20 \
    $index $fq1 $fq2 |\
    samtools view -bS -@ 20 - |\
    samtools sort -@ 20 - \
    -o $out
samtools index $out
samtools idxstats $out > $out.reads
