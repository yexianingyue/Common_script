#!/usr/bin/bash

set -e

if [ $# -lt 4 ] || [ $# -gt 5 ];then
    echo -e "example:"
    echo -e "       $0 input.fasta 2000 ./output/out input.fq.gz"
    echo -e "       $0 input.fasta 2000 ./output/out input.fq1.gz input.fq2.gz"
    echo -e "  2000是对于input.fasta的过滤长度，如果为0，代表不过滤, 也可以是其他值"
    exit 0
fi

function check_in(){
    # 检查输入文件
    if [ ! -f $1 ];then
        echo "No such input file $1"
        exit 127
    fi
}

function check_out(){
    # 检查输出文件前缀
    # ${1%/*} 删除 $1 从右边起，第一个 / 以及右边的所有字符
    # 这边就不创建了，用户自己手动创建为好
    if [ -d $1 ] || [ -f $1 ];then
        echo "You should give me a prefix for the output, not the directory or file."
        exit 127
    elif [[ $1 =~ "/" ]] || [ ! -d ${1%/*} ];then
        echo "No such directory ${1%/*}"
        exit 127
    fi
    elif [ -f ${1}.depth ];then
        echo "${1}.depth  already exists, no need to run it again."
        exit 127
    fi
}

# -----------------------
# 软件
BWA="/usr/local/bin/bwa"
SAMTOOLS="/usr/local/bin/samtools"
JGI="/usr/local/bin/jgi_summarize_bam_contig_depths"
SEQKIT="/usr/local/bin/seqkit"

#--------------
# 检查文件
out_f=$3
check_out $out_f
check_in $1

# -------------
# seqkit 过滤fasta
if [ $2 -ne 0 ];then
    fa="${out_f}.filter.fa.gz"
    echo "filter $1 : $2 :" > ${out_f}.run.log
    echo "$SEQKIT seq -g -m $2 $1 -o $fa" >> ${out_f}.run.log
    $SEQKIT seq -g -m $2 $1 -o $fa
else
    fa=$1
fi


# -------------
# bwa 建库
check_in $fa
echo "run make bwa index:" >> ${out_f}.run.log
echo "$BWA index -p  ${out_f}.bwa.index $fa" >> ${out_f}.run.log
$BWA index -p ${out_f}.bwa.index $fa 


# -------------
# map、计算深度
# 这个是如果硬盘存储空间不够的话，用这个方法
if [ $# -eq 2 ];then
    fq=$4
    check_in $fq
    cmd="$BWA mem -t 30 ${out_f}.bwa.index $fq"
    echo "run bwa:" >> ${out_f}.run.log
else
    fq1=$4
    fq2=$5
    check_in $fq1
    check_in $fq2
    cmd="$BWA mem -t 30 ${out_f}.bwa.index $fq1 $fq2"
    echo "run bwa:" >> ${out_f}.run.log
fi

$cmd |\
    $SAMTOOLS view -bS - -o ${out_f}.bam\
    && $SAMTOOLS sort ${out_f}.bam -o ${out_f}.sort.bam -@ 30 \
    && rm ${out_f}.bam \
    && $JGI --outputDepth ${out_f}.depth ${out_f}.sort.bam \
    && rm ${out_f}.bwa.index.* ${out_f}.sort.bam

