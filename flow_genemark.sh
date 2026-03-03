#!/usr/bin/bash
set -e

if [ $# -lt 3 ];then
    echo "$0 <fasta|.gz> <temp_work_dict> <out_prefix> [seq_name_preifx] [min_contig]"
    echo "min_contig (default: 20000). Maybe this parameter has no result because its value is too large."
    echo "seq_name_preifx 预测完的蛋白序列，是否需要在名字前叠加新的名字,默认不加"
    echo -e "\t预测的蛋白序列，命名格式默认是: ctg_id.order_g"
    exit 0
fi

fa=$1
temp_wd=$2
out_pref=$3
seq_name=${4:-}
min_contig=${5:-20000}
tmp_fa=$fa

#-------------------------
#       software
shopt -s expand_aliases
alias gmes_petap.pl="/share/data1/software/genemark_es/gmes_petap.pl"
alias get_sequence_from_GTF.pl="/share/data1/software/genemark_es/get_sequence_from_GTF.pl"



#if [ -f $out_pref.faa  -a  -f $out_pref.ffn ] || [ -f $out_pref.faa.gz  -a  -f $out_pref.ffn.gz ];
if [ -f $out_pref.faa -a -f $out_pref.ffn ] || [ -f $out_pref.faa.gz -a $out_pref.ffn.gz ];
then
    echo "skip $fa because output file is existed" >&2;
    exit 127
fi

if [ ! -f $temp_wd/genemark.gtf ];then 
    # 判断有无临时文件
    if [ ! -d $temp_wd ];then
        mkdir -p $temp_wd
    fi
    # 判断之前是否跑过
    if [ -f $temp_wd/gmes.log ];then
        exit 0
    fi
    
    # 判断是否是压缩文件.gz
    if echo $fa | grep -q '.gz$' ;
    then 
        pigz -dc $fa > $temp_wd/input_temp.fna;
        tmp_fa=$temp_wd/input_temp.fna;
    fi
    # 因为这一步中，软件不能识别压缩文件，所以必须是非压缩的
    gmes_petap.pl --fungus --ES --min_contig $min_contig --cores 20 \
        --sequence $tmp_fa \
        --work_dir $temp_wd
fi


( [ ! -f ${out_pref}.faa ] || [ ! -f ${out_pref}.faa.gz ] ) && { get_sequence_from_GTF.pl $temp_wd/genemark.gtf  $fa $out_pref $seq_name \
        && mv $temp_wd/genemark.gtf $out_pref.gtf \
        && rm -r $temp_wd; } || exit 127

