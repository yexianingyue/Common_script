#!/usr/bin/bash
set -e
if [ $# -ne 2 ];then
    echo "$0 <fq1> <out_dir>"
    exit 127
fi

fq1=$1
out=$2
prefix=${out##*/}
if [ -f $out/${prefix}.temp_pathabundance.tsv ]
then
    echo "Already have the results"
    exit 0
fi

pigz -dc $fq1 | head -n 4000000 > ${out}.temp.fq
# fastp  -w 4 -q 20 -u 30 -n 5 -y -Y 30  --trim_poly_g --trim_poly_x -j /dev/null -h /dev/null -l 90 -i $fq1 --stdout 2>/dev/null | head -n 8000000 > ${out}.temp.fq

humann3 --threads 8 \
    --input ${out}.temp.fq \
    --output $out\
    --memory-use maximum\
    --search-mode uniref50\
    --nucleotide-identity-threshold 90

if [ -f $out/${prefix}.temp_pathabundance.tsv ];
then
    rm ${out}.temp.fq
    rm -r $out/${prefix}.temp_humann_temp
    humann_renorm_table --input  $out/${prefix}.temp_pathabundance.tsv --units "relab" --output $out/${prefix}.pathabundance_relative.tsv # 转化为相对丰度
fi

# /share/data1/software/miniconda3/lib/python3.8/site-packages/humann/config.py
# https://biocyc.org/account-required.shtml?redirect=http%3a%2f%2fbiocyc.org%2fHUMAN%2fNEW-IMAGE
