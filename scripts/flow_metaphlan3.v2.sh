#!/usr/bin/bash
set -e # 如果出错，就不再执行下一步

fq1=$1 # 哪一端的reads无所谓

if [[ $1 =~ "," ]];then
    fq1=`echo $1|cut -d "," -f 1`
    fq2=`echo $1|cut -d "," -f 2`
    if [ ! -f $fq1 ] || [ ! -f $fq2 ];then
        echo "No such file or directory"
        exit 127
    fi
fi

if [ $# -eq 0 ]||[ $# -eq 1 ]||[ ! -f $fq1 ];then
    echo "$0 <fq|fq1,fq2> <output_prefix>"
    exit 127
fi

db_path="/share/data1/software/miniconda3/lib/python3.8/site-packages/MetaPhlAn-3.0.7-py3.8.egg/metaphlan/metaphlan_databases"
MP="/share/data1/software/miniconda3/bin/metaphlan"
BW="/usr/local/bin/bowtie2 --mm --sam-no-hd --sam-no-sq --no-unal --fast"
out_f=$2

# bowtie2 --mm -u 10000000 --sam-no-hd --sam-no-sq --no-unal --very-sensitive -S ${out_f}.temp.sam -x ${db_path}/mpa_v30_CHOCOPhlAn_201901 -U ${in_f} \
${BW} -p 8  -S ${out_f}.temp.sam -x ${db_path}/mpa_v30_CHOCOPhlAn_201901 -U ${fq1} 2> ${out_f}.bowtie.log \
    && ${MP}  ${out_f}.temp.sam --input_type sam -o ${out_f}.profile \
    && rm ${out_f}.temp.sam

