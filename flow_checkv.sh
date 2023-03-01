#!/usr/bin/bash
set -e

# 读取参数
if [ ! -f $1 ] || [ $# -lt 2 ] || [ $# -gt 3 ];then
    echo "$0 <fasta> <out_dir> [<threads:80>]"
    exit 127
fi
# 输入输出需要不同
if [ $1 == $2 ];then
    echo "<in_f> == <out_f>"
    exit 127
fi

in_f=$1
out_f=$2
threads=${3:-80}

/share/data2/guorc/Software/conda/checkv/bin/checkv end_to_end \
    -d /share/data2/guorc/Software/conda/checkv/checkv-db-v0.6/ \
    -t ${threads} \
    ${in_f}  \
    ${out_f} \
    > ${out_f}.log 2>&1
