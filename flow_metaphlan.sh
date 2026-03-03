#!/usr/bin/bash


#-----------------------------------
#       Configure
sotf_bw=/share/data1/software/miniconda3/envs/metaphlan4/bin/bowtie2
soft_mp=/share/data1/software/miniconda3/envs/metaphlan4/bin/metaphlan

# metaphlan_db="mpa_vJan21_CHOCOPhlAnSGB_202103"
last_db="mpa_vOct22_CHOCOPhlAnSGB_202403"
metaphlan_db="mpa_vJan25_CHOCOPhlAnSGB_202503"


db_base="/share/data1/Database/metaphlan4/"
bwt_db="${db_base}/${metaphlan_db}/${metaphlan_db}"
mpa_db="${db_base}/${metaphlan_db}"

( [ $# -lt 2 ] || [[ $1 =~ "-h" ]] ) && \
    echo -e "\n\tUsage: $0 <fq>|<fq1,fq2>|<fa>|<fa1,fa2>  <out_prefix> [nreads:999999999]" && \
    echo -e "\n\tVersion: metaphlan4\n\tDatabase: \033[32m${metaphlan_db}\033[0m \n\tLast Database: \033[31m${last_db}\033[0m\n\n" && exit 127


set -f
set -e # 如果出错，就不再执行下一步

fq1=$1 # 哪一端的reads无所谓
nreads=${3:-999999999}

if [[ $1 =~ "," ]];then
    fq1=`echo $1|cut -d "," -f 1`
    fq2=`echo $1|cut -d "," -f 2`
    if [ ! -f $fq1 ] || [ ! -f $fq2 ];then
        echo "No such file or directory"
        exit 127
    fi
fi

if [ $# -eq 1 ] || [ ! -f $fq1 ];then
    echo "$0 <fq|fq1,fq2|fa|fa1,fa2> <output_prefix>"
    echo "$#"
    exit 127
fi

#----------------------------------
#               参数
out_f=$2

## 判断任务是否重新运行
if [ -f ${out_f}.ok ];then
    echo -e "${out_f}.ok  -> exit"
    exit 0
fi

if [ -f ${out_f}.running ];then
    echo -e "The task is either running or has terminated unexpectedly. \nDelete the file: ${out_f}.running, and then run it again."
    exit 127
fi


#-----------------------------------
#       parameters
flag="" # 如果是fastq，bowtie2就不用添加其他参数
content=`less $fq1 | head -n 3 | tail -n 1`
if [ $content != "+" ];then flag=" -f ";fi



#-----------------------------------
## 异常终止时，删除这个文件
clean_tmp(){
    echo "Accidental termination"
    rm ${out_f}.running;
    exit 127
}

trap 'clean_tmp' SIGINT SIGTERM

#-----------------------------------
## start
touch ${out_f}.running

## 运行bowtie2
if [ ! -f ${out_f}.bowtie.ok ];then
    ${sotf_bw} --mm -u $nreads ${flag} -p 8 --sam-no-hd --sam-no-sq --no-unal --fast -S ${out_f}.temp.sam -x ${bwt_db} -U ${fq1} 2> ${out_f}.bowtie.log \
        && touch  ${out_f}.bowtie.ok
fi

## 看看有多少条reads
if [ -f ${out_f}.bowtie.log ];then
    tot_reads=`head -n 1 ${out_f}.bowtie.log | cut -d " " -f 1`
else
    echo "can't find file ${out_f}.bowtie.log. parameter: --nreads ${tot_reads}"
    tot_reads=nreads
fi


if [ -f ${out_f}.bowtie.ok ];then
    ${soft_mp} --bowtie2db "${mpa_db}" -x ${metaphlan_db} -t rel_ab_w_read_stats --nreads $tot_reads ${out_f}.temp.sam --input_type sam -o ${out_f}.profile \
        && mv ${out_f}.running ${out_f}.ok \
        && rm ${out_f}.bowtie.ok ${out_f}.temp.sam
fi

