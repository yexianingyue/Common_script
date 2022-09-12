#!/usr/bin/bash
set -e

if [ $# -lt 4 ];then
    echo "$0 <fq1> <fq2> <out_prefix> <k-list>"
    echo "You Must change the parameter befor you use it."
    exit 127
fi

fq1=$1
fq2=$2
out=$3
kl=$4

#fastp -i $fq1 -I $fq2 -q 20 -u 30 -n 5 -y -Y 30 -l 60 --trim_poly_g -o $out.1.fq.gz -O $out.2.fq.gz -j /dev/null -h /dev/null -w 4 2> $out.log 
megahit -1 $fq1 -2 $fq2 \
	--k-list $kl \
	-t 40 \
	-o $out --out-prefix $out 2> $out.megahit.log

if [ $? -eq 0 ];then
    rm -rf $out/intermediate_contigs/
fi

#rm $fq2
