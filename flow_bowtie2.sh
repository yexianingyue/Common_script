#!/usr/bin/bash

set -e # 如果出错，就不再执行下一步

if [ $# -lt 4 ];then
    echo "$0 <fq1> <fq2> <index> <out_prefix>"
    exit 127
fi

fq1=$1
fq2=$2
index=$3
p=$4


bowtie2 --end-to-end --mm --fast -1 $fq1 -2 $fq2 -x $index --no-head --no-unal --no-sq -S $p.sam -p 20 2> $p.log
#bowtie2 --end-to-end --fast -U $fq1 -x geneset -u 2000000 --no-head --no-unal --no-sq -S $p.sam -p 50 2> $p.log

less $p.sam | perl -e 'while(<>){if(/^\S+\s+\S+\s+(\S+)\s+/){$h{$1}++;}} for(sort keys %h){print "$_\t$h{$_}\n";}' > $p.rc

rm $p.sam
