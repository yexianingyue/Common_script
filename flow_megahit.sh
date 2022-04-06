#!/usr/bin/bash

fq1=$1
fq2=$2
out=$3
fastp -i $fq1 -I $fq2 -q 20 -u 30 -n 5 -y -Y 30 -l 60 --trim_poly_g -o $out.1.fq.gz -O $out.2.fq.gz -j /dev/null -h /dev/null -w 4 2> $out.log 
megahit -1 $out.1.fq.gz -2 $out.2.fq.gz --k-list 21,41,61,81,101,121,141 -o $out --out-prefix $out
