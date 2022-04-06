#!/usr/bin/bash
set -e

if [ $# -lt 4 ];then
    echo "$0 <fasta> <temp_work_dict> <out_prefix> <seq_name_preifx>"
    echo "--min_contig (default: 20000). Maybe this parameter has no result because its value is too large."
    exit 0
fi

fa=$1
temp_wd=$2
out_pref=$3
seq_name=$4
min_contig=${5:-200000}

if [ ! -f $temp_wd/genemark.gtf ];then 
    if [ ! -d $temp_wd ];then
        mkdir $temp_wd
    fi
    if [ -f $temp_wd/gmes.log ];then
        exit 0
    fi

    /share/data1/software/genemark_es/gmes_petap.pl --fungus --ES --min_contig $min_contig --cores 30 \
        --sequence $fa \
        --work_dir $temp_wd
fi

echo "detected $temp_wd/genemark.gtf"

if [ ! -f $3.faa ];then
    /share/data1/software/genemark_es/get_sequence_from_GTF.pl \
        $temp_wd/genemark.gtf  $fa $out_pref \
        $seq_name
fi
