#!/usr/bin/bash

if [ $# -lt 4 ];then
    echo "$0 <fq1> <fq2> <index> <out_prefix>"
    exit 127
fi

fq1=$1
fq2=$2
index=$3
p=$4

#bowtie2 --end-to-end --fast -1 $fq1 -2 $fq2 -x /share/data1/lish/download/human_db/human_genome --no-head -S $p.sam -p 15 2> $p.nohost.log
bowtie2 --end-to-end --fast -1 $fq1 -2 $fq2 -x $index  --no-head -S $p.sam -p 12 2> $p.nohost.log

less $p.sam | perl -ne 'chomp;@s=split /\s+/;if($s[1]==77){print "\@$s[0]/1\n$s[9]\n+\n$s[10]\n";}elsif($s[1]==141){print STDERR "\@$s[0]/2\n$s[9]\n+\n$s[10]\n";}' > $p.nohost.1.fq 2> $p.nohost.2.fq

rm $p.sam -f 

pigz -p 20 $p.nohost.1.fq
pigz -p 20 $p.nohost.2.fq

