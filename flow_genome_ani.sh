#!/usr/bin/bash

if [ $# -lt 3 ];then
    echo ""
    echo -e "\tUsage:"
    echo -e "\n\t\t$0 <\033[32mquery_list\033[0m> <\033[32mref_list\033[0m> <\033[32moutput\033[0m>\n"
    echo ""
    echo -e "\n\t\033[32mquery_list\033[0m:"
    echo -e "\t\t/path/to/genomes.1.fa"
    echo -e "\t\t/path/to/genomes.2.fa.gz"
    echo -e "\t\t/path/to/genomes.3.fasta"
    echo ""
    echo -e "\n\t\033[32mref_list\033[0m: 与\033[32mquery_list\033[0m格式一致"
    echo ""
    exit 127
fi

set -e
ulimit -u 100000

query_list=$1
ref_list=$2
output=$3
threads=34
top=1 # mash距离最近的多少个基因组用于计算fastANI

FASTANI="/usr/local/bin/fastANI"
cmd_ani="$FASTANI  --minFraction 0 "

MASH="/share/data1/software/mash/v2.3/mash"


## 建库
if [ ! -f ${output}.query.msh.ok ];then
    echo "build query mash"
    $MASH sketch -s 10000 -p $threads -l $query_list -o ${output}.query.msh  2> ${output}.query.msh.err > ${output}.query.msh.log  \
        && touch ${output}.query.msh.ok \
        || ! mv ${output}.query.msh.ok ${output}.query.msh.fail || exit 127
fi

if [ ! -f ${output}.ref.msh.ok ];then

    echo "build ref mash"
    $MASH sketch -s 10000 -p $threads -l $ref_list -o ${output}.ref.msh 2> ${output}.ref.msh.err > ${output}.ref.msh.log \
        && touch ${output}.ref.msh.ok \
        || ! mv ${output}.ref.msh.ok ${output}.ref.msh.fail || exit 127
fi


## 计算距离
if [ ! -f ${output}.dist.ok ];then
    echo "calc dist"
    $MASH dist -p $threads ${output}.ref.msh ${output}.query.msh | awk '$3 < 1' > ${output}.dist \
        && touch ${output}.dist.ok \
        || ! mv ${output}.dist.ok ${output}.dist.running || exit 127
fi


## 每个查询序列挑选最好的一个
if [ ! -f ${output}.dist.top${top}.ok ];then
    echo "select top ${top}"
    cat  ${output}.dist | sort -k 3,3g --parallel=${threads} | perl -e '%h; while(<>){chomp; @l=split/\t/; print "$_\n" if $h{$l[1]} < '"${top}"'; $h{$l[1]}++}'  >> ${output}.dist.top${top} && touch ${output}.dist.top${top}.ok
fi


echo "run fastANI"
cat ${output}.dist.top${top} | perl -ne 'chomp; @l=split/\t/; print "'"$cmd_ani"' -r $l[0] -q $l[1] -o /dev/stdout -t 4\n"' | parallel -j ${threads} -k > ${output}.ani


rm ${output}.query* ${output}.ref.* 
