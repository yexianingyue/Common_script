#!/usr/bin/bash

if [ $# -lt 3 ];then
    echo "$0 <fq1> <index> <out_prefix>"
    exit 127
fi

fq1=$1
index=$2 # {3:-"/share/data1/lish/download/human_db/human_genome"}
p=$3

if [ ! -f $p.sam.done ];then
    bowtie2 --end-to-end --mm --fast -U $fq1 -x ${index}  --no-head -S $p.sam -p 12 2> $p.nohost.log \
        && touch $p.sam.done
fi

less $p.sam | perl -ne 'chomp;@s=split /\s+/;if($s[1]==4){print "\@$s[0]/1\n$s[9]\n+\n$s[10]\n";}' > >(pigz > $p.clean_nohost.single.fq.gz) \
    && rm $p.sam $p.sam.done -f || ! echo "ERROR" || exit 127
