#!/usr/bin/bash
set -e

if [ $# -ne 2 ];then
    echo "$0 <merged_metaphlan.profile> <out_prefix>"
    exit 127
fi

if [[ $2 == "" ]];then
    echo "out_prfix is illegal"
    exit 127
fi

in_f=$1
out_f=`realpath $2`
pid=$$

tmp=${out_f}_${pid}_temp
out_dir=${out_f%/*}
out_name=${out_f##*/}
mkdir ${tmp}
head -1 $in_f > ${tmp}/title

grep -E "(p__)|(^ID)" ${in_f} | grep -v "t__" | grep -v "s__" | grep -v "g__" | grep -v "f__" |grep -v "o__" | grep -v "c__"|sed 's/^.*p__/p__/g' > ${tmp}/${out_name}_phylum.profile
grep -E "(c__)|(^ID)" ${in_f} | grep -v "t__" | grep -v "s__" | grep -v "g__" | grep -v "f__" |grep -v "o__"|sed 's/^.*c__/c__/g' > ${tmp}/${out_name}_class.profile
grep -E "(o__)|(^ID)" ${in_f} | grep -v "t__" | grep -v "s__" | grep -v "g__" |grep -v "f__"|sed 's/^.*o__/o__/g' > ${tmp}/${out_name}_order.profile
grep -E "(f__)|(^ID)" ${in_f} | grep -v "t__" | grep -v "s__" | grep -v "g__" |sed 's/^.*f__/f__/g' > ${tmp}/${out_name}_family.profile
grep -E "(g__)|(^ID)" ${in_f} | grep -v "t__" | grep -v "s__" |sed 's/^.*g__/g__/g' > ${tmp}/${out_name}_genus.profile
grep -E "(s__)|(^ID)" ${in_f} | grep -v "t__" | sed 's/^.*s__/s__/g' > ${tmp}/${out_name}_species.profile
\ls ${tmp}/*.profile | perl -ne 'chomp;$_=~/(.*\/)(.*.profile$)/; print "cat $1/title  $_ > '"${out_dir}"'/$2\n"'  | sh && rm -r ${tmp}

#ls ./${tmp}/${out_f}_profile | awk '{print "cat '"${tmp}"'/title "'"${tmp}"'" > "$1".f; mv "$1".f "$1}' | sh && rm title
