#!/usr/bin/bash

if [ $# -lt 2 ] || [[ $1 =~ "-h" ]];then
    echo "$0 <fq>|<fq1,fq2>  <out_prefix>"
    echo "Version: metaphlan4"
    exit 127
fi

set -f
set -e # 如果出错，就不再执行下一步

fq1=$1 # 哪一端的reads无所谓

if [[ $1 =~ "," ]];then
    fq1=`echo $1|cut -d "," -f 1`
    fq2=`echo $1|cut -d "," -f 2`
    if [ ! -f $fq1 ] || [ ! -f $fq2 ];then
        echo "No such file or directory"
        exit 127
    fi
fi

if [ $# -eq 1 ]||[ ! -f $fq1 ];then
    echo "$0 <fq|fq1,fq2> <output_prefix>"
    exit 127
fi

db_path="/share/data1/Database/metaphlan4/mpa_vJan21_CHOCOPhlAnSGB_202103"
sotf_bw=/share/data1/software/miniconda3/envs/metaphlan4/bin/bowtie2
soft_mp=/share/data1/software/miniconda3/envs/metaphlan4/bin/metaphlan

out_f=$2

###### bowtie2 --mm -u 10000000 --sam-no-hd --sam-no-sq --no-unal --very-sensitive -S ${out_f}.temp.sam -x ${db_path}/mpa_v30_CHOCOPhlAn_201901 -U ${in_f} \
${sotf_bw} --mm -p 8 --sam-no-hd --sam-no-sq --no-unal --fast -S ${out_f}.temp.sam -x ${db_path} -U ${fq1} 2> ${out_f}.bowtie.log \
    && ${soft_mp} ${out_f}.temp.sam --input_type sam -o ${out_f}.profile \
    && rm ${out_f}.temp.sam

# combine_file_zy_folder_allsample.py -D profiles/ --skip 5 -v 3 -suffix .profile -s 0 -o metaphlan4.profile
# 
# mkdir taxonomy 
# head -1 metaphlan4.profile > title
# 
# grep -E "(p__)|(^ID)" metaphlan4.profile | grep -v "t__" | grep -v "s__" | grep -v "g__" | grep -v "f__" |grep -v "o__" | grep -v "c__"|sed 's/^.*p__//g' > taxonomy/phylum_relative_abundance.tsv
# grep -E "(c__)|(^ID)" metaphlan4.profile | grep -v "t__" | grep -v "s__" | grep -v "g__" | grep -v "f__" |grep -v "o__"|sed 's/^.*c__//g' > taxonomy/class_relative_abundance.tsv
# grep -E "(o__)|(^ID)" metaphlan4.profile | grep -v "t__" | grep -v "s__" | grep -v "g__" |grep -v "f__"|sed 's/^.*o__//g' > taxonomy/order_relative_abundance.tsv
# grep -E "(f__)|(^ID)" metaphlan4.profile | grep -v "t__" | grep -v "s__" | grep -v "g__" |sed 's/^.*f__//g' > taxonomy/family_relative_abundance.tsv
# grep -E "(g__)|(^ID)" metaphlan4.profile | grep -v "t__" | grep -v "s__" |sed 's/^.*g__//g' > taxonomy/genus_relative_abundance.tsv
# grep -E "(s__)|(^ID)" metaphlan4.profile | grep -v "t__" | sed 's/^.*s__//g' > taxonomy/species_relative_abundance.tsv
# ls ./taxonomy/*.tsv | awk '{print "cat title "$1" > "$1".f; mv "$1".f "$1}' | sh
