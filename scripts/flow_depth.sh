#!/usr/bin/bash
shopt -s expand_aliases

set -e

if [ $# -lt 4 ] || [ $# -gt 5 ];then
    echo -e "\n"
    echo -e "\texample:"
    echo -e "\t   For \e[33mSingle\e[0m sequencing:"
    echo -e "\t       $0 <\e[32minput.fasta\e[0m> <\e[32m1000\e[0m> <\e[32m./output/out\e[0m> <\e[32minput.fq.gz\e[0m>"
    echo -e "\n"
    echo -e "\t   For \e[33mPaired\e[0m sequencing:"
    echo -e "\t       $0 <\e[32minput.fasta\e[0m <\e[32m1000\e[0m> <\e[32m./output/out\e[0m> <\e[32minput.fq1.gz\e[0m> <\e[32minput.fq2.gz\e[0m>"
    echo -e "\n"
    echo -e "\t   Note:"
    echo -e "\t       1、1000是对于input.fasta的过滤长度，如果为0，代表不过滤, 也可以是其他值"
    echo -e "\t          宏基因组组装分箱建议1000， 单菌测序建议500. (是因为1000主要是为了捞回来16S序列)"
    echo -e "\n"
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
    elif [[ $1 =~ "/" ]] && [ ! -d ${1%/*} ];then
        echo "No such directory ${1%/*}"
        exit 127
    fi
    if [ -f ${1}.depth ];then
        echo "${1}.depth  already exists, no need to run it again."
        exit 127
    fi
}

# -----------------------
# 软件
alias bwa='/usr/local/bin/bwa'
alias samtools='/usr/local/bin/samtools'
alias JGI='/usr/local/bin/jgi_summarize_bam_contig_depths'
alias seqkit='/usr/local/bin/seqkit'
# alias gc_depth.stat.pl='perl /home/lish/bin/gc_depth.stat.pl'

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
    echo "seqkit seq -g -m $2 $1 -o $fa" >> ${out_f}.run.log
    seqkit seq -g -m $2 $1 -o $fa
else
    fa=$1
fi


# -------------
# bwa 建库
check_in $fa
echo "run make bwa index:" >> ${out_f}.run.log
echo "bwa index -p  ${out_f}.bwa.index $fa" >> ${out_f}.run.log
bwa index -p ${out_f}.bwa.index $fa 


# -------------
# map、计算深度
# 这个是如果硬盘存储空间不够的话，用这个方法
if [ $# -eq 2 ];then
    fq=$4
    check_in $fq
    cmd="bwa mem -t 30 ${out_f}.bwa.index $fq"
    echo "run bwa: $cmd" >> ${out_f}.run.log
else
    fq1=$4
    fq2=$5
    check_in $fq1
    check_in $fq2
    cmd="bwa mem -t 30 ${out_f}.bwa.index $fq1 $fq2"
    echo "run bwa: $cmd" >> ${out_f}.run.log
fi

## mapping : ${out_f}.sam.ok
( [ ! -f ${out_f}.sam.ok ] ) && { $cmd > ${out_f}.sam 2> ${out_f}.bwa.log  && touch ${out_f}.sam.ok || ! rm ${out_f}.sam || exit 127; }
## sam to bam : ${out_f}.bam.ok
( [ ! -f ${out_f}.bam.ok ] ) && { samtools view -bS ${out_f}.sam -o ${out_f}.bam -@ 30 && touch ${out_f}.bam.ok && rm ${out_f}.sam || ! rm ${out_f}.bam || exit 127 ; }
## sort bam :  ${out_f}.sort.bam.ok
( [ ! -f ${out_f}.sort.bam.ok ] ) && { samtools sort ${out_f}.bam -o ${out_f}.sort.bam -@ 30 && touch ${out_f}.sort.bam.ok && rm ${out_f}.bam || ! rm ${out_f}.sort.bam || exit 127; }
## coverage
( [ ! -f ${out_f}.depth.ok ] ) && { JGI --outputDepth ${out_f}.depth ${out_f}.sort.bam && touch ${out_f}.depth.ok || ! rm ${out_f}.depth || exit 127;}
## remove tmp file
( [ -f ${out_f}.depth.ok ] ) && { rm ${out_f}.sam.ok ${out_f}.bam.ok  ${out_f}.sort.bam.ok ${out_f}.depth.ok ${out_f}.sort.bam ${out_f}.bwa.index.* ${out_f}.run.log|| exit 127; }
( [ -f ${out_f}.filter.gz ] ) && { rm ${out_f}.filter.gz || exit 127; }


# gc_depth.stat.pl -r ../assem_spades/A702-92.scaffolds.fasta -d A702-92.sdep -o x.pdf
