#!/bin/bash
# by grc
set -e

if [ "$#" -ne "2" ]; then
    echo -e "\nusage: sh $0 <AA faa> <output file>\n" 
    exit 2
fi


prot=$1
outf=$2

diamond blastp --threads 60 --max-target-seqs 10 --db /share/data1/lish/download/Microbiome_virus/tot --query $prot --outfmt 6 --out $outf.bt --quiet 
perl /share/data2/guorc/script/get_pep.length.pl $prot $outf.len
filter_blast -i $outf.bt -o $outf.bt2 --qfile $outf.len --qper 50 --identity 30 --tops 40 --score 50 
grep '^>' $prot | sed 's/^>//' |perl -pne 's/_(\d+) #.*//' |sort |uniq -c |awk '{print $2"\t"$1}' > $outf.ngenes
perl /share/data2/guorc/script/WGS/Virus/vctg_stat.v2.pl $outf.bt2 /share/data1/lish/download/Microbiome_virus/tot.tax $outf.ngenes $outf.bt2.f
msort -k 1,rn3,rn6 $outf.bt2.f | perl -ne 'chomp;@s=split /\s+/;next if exists $h{$s[0]}; $pct=$s[2]/$s[4]; next unless $pct>=0.25 or ($pct>=0.18 and $s[5]>=40); printf "$s[0]\t$s[2]/$s[4]\t%.2f\t$s[1]\n",$s[5];$h{$s[0]}=1;' > $outf.tax_family
