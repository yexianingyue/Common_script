#!/usr/bin/bash
set -e

if [ $# -lt 2 ] || [ $# -gt 3 ];then
    echo -e "\n\tUsage:\t$0 <merged_metaphlan.profile> <out_prefix> [full/short:default]"
    echo -e "\t\tfull  -> 当前分类水平的上级所有分类"
    echo -e "\t\tshort -> 当前分类"
    exit 127
fi

if [[ $2 == "" ]];then
    echo "out_prfix is illegal"
    exit 127
fi

in_f=$1
out_f=`realpath $2`
flag=${3:-"short"}
pid=$$

tmp=${out_f}_${pid}_temp
out_dir=${out_f%/*}
out_name=${out_f##*/}
mkdir ${tmp}
head -1 $in_f > ${tmp}/title

if [ $flag == "short" ];then
    grep -E "(p__)" ${in_f} | grep -v "t__" | grep -v "s__" | grep -v "g__" | grep -v "f__" |grep -v "o__" | grep -v "c__"|sed 's/^.*p__/p__/g' > ${tmp}/${out_name}_phylum.profile
    grep -E "(c__)" ${in_f} | grep -v "t__" | grep -v "s__" | grep -v "g__" | grep -v "f__" |grep -v "o__"|sed 's/^.*c__/c__/g' > ${tmp}/${out_name}_class.profile
    grep -E "(o__)" ${in_f} | grep -v "t__" | grep -v "s__" | grep -v "g__" |grep -v "f__"|sed 's/^.*o__/o__/g' > ${tmp}/${out_name}_order.profile
    grep -E "(f__)" ${in_f} | grep -v "t__" | grep -v "s__" | grep -v "g__" |sed 's/^.*f__/f__/g' > ${tmp}/${out_name}_family.profile
    grep -E "(g__)" ${in_f} | grep -v "t__" | grep -v "s__" |sed 's/^.*g__/g__/g' > ${tmp}/${out_name}_genus.profile
    grep -E "(s__)" ${in_f} | grep -v "t__" | sed 's/^.*s__/s__/g' > ${tmp}/${out_name}_species.profile
else
    grep -E "(p__)" ${in_f} | grep -v "t__" | grep -v "s__" | grep -v "g__" | grep -v "f__" |grep -v "o__" | grep -v "c__" > ${tmp}/${out_name}_phylum.profile
    grep -E "(c__)" ${in_f} | grep -v "t__" | grep -v "s__" | grep -v "g__" | grep -v "f__" |grep -v "o__" > ${tmp}/${out_name}_class.profile
    grep -E "(o__)" ${in_f} | grep -v "t__" | grep -v "s__" | grep -v "g__" |grep -v "f__" > ${tmp}/${out_name}_order.profile
    grep -E "(f__)" ${in_f} | grep -v "t__" | grep -v "s__" | grep -v "g__" > ${tmp}/${out_name}_family.profile
    grep -E "(g__)" ${in_f} | grep -v "t__" | grep -v "s__" > ${tmp}/${out_name}_genus.profile
    grep -E "(s__)" ${in_f} | grep -v "t__" > ${tmp}/${out_name}_species.profile
fi

\ls ${tmp}/*.profile | perl -ne 'chomp;$_=~/(.*\/)(.*.profile$)/; print "cat $1/title  $_ > '"${out_dir}"'/$2\n"'  | sh && rm -r ${tmp}
