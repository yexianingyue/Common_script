#!/usr/bin/bash
if [ $# -ne 2 ]
then
    echo $0 "<sam> <out_prefix>"
    exit 0
fi
inf=$1
outf=$2

awk -F "\t" '{print "@"$1NR"\n"$10"\n+\n"$11}' $inf > >(gzip > $outf.fq.gz)
