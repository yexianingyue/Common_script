#!/usr/bin/bash

if [ $# -lt 3 ];then
    echo "$0 <fq>|<fq1,fq2> <sample_id> <out_prefix>"
    exit 127
fi

fqs=$1
sample_id=$2
out=$3


#source activate /share/data1/zhangy/software/miniconda/envs/metaphlan3
#/usr/bin/time -f "$out time: %U" -a -o metaphlan3.time.log \
/share/data1/software/miniconda3/bin/metaphlan \
    $fqs \
    --bowtie2db /share/data1/Database/metaphlan30/  \
    --ignore_eukaryotes \
    --sample_id_key $sample_id \
    --nproc 60 --input_type fastq \
    --bowtie2_exe /usr/bin/bowtie2 \
    --bowtie2out $out.bz2 \
    -o $out.profile

