#!/usr/bin/bash

set -e # 如果出错，就不再执行下一步

if [ $# -ne 1 ]||[ ! -f $1 ];then
    echo "$0 <checkv_report_hmmsearch.tsv>"
    exit 127
fi

checkv_hmm=$1
checkv_db_hmm="/share/data2/guorc/Software/conda/checkv/checkv-db-v0.6/hmm_db/checkv_hmms.tsv"
perl -e '%h;open D,"$ARGV[0]";while(<D>){chomp;@l=split/\t/;$h{$l[2]}=$l[7]};open I,"$ARGV[1]";while(<I>){chomp;next if /^#/; $_=~/(\S+)\s+\-\s+(\S+)\s+/;$t=$2;$t=$h{$2};print "$1\t$t\n"}' ${checkv_db_hmm} ${checkv_hmm}
