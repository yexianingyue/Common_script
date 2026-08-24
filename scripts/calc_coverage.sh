#!/usr/bin/bash

set -e # 如果出错，就不再执行下一步

if [ $# -gt 3 ] || [ $# -lt 2 ];then
    echo "$0 <sam> <out> [<title_sam>]"
    exit 127
fi

sam_file=$1 # sam
out_f=$2
title_sam=${3:-""}
cat  $title_sam  $sam_file |\
    samtools view -bS - |\
    samtools sort - |\
    samtools coverage - -o $out_f
