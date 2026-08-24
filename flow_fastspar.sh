#!/usr/bin/bash

if [ $# -ne 2 ];then
    echo ""
    echo -e "Usage:\t$0 profiles prefix_output"
    echo ""
    exit 0
fi



inf=$1
outp=$2
threads=40


source activate fastspar
fastspar --otu_table $inf  --correlation ${outp}.correlation.tsv --covariance ${outp}.covariance.tsv -i 20 --threads ${threads}
mkdir ${outp}.bootstrap_correlation ${outp}.bootstrap_counts
fastspar_bootstrap -t 64 --otu_table ${inf}  -n 1000 --prefix ${outp}.bootstrap_counts/x


\ls ${outp}.bootstrap_counts/*.tsv | parallel --plus  -j 10 echo "fastspar --otu_table ${outp}.bootstrap_counts/{/} --correlation ${outp}.bootstrap_correlation/{/} --covariance ${outp}.bootstrap_correlation/cov_{/} -i 5 -t 30  -y"  > ${outp}.r1.sh;
parallel -j ${threads} < ${outp}.r1.sh;

## 这个会占用巨量的空间，最后删除
\ls ${outp}.bootstrap_counts/*.tsv | parallel --plus  -j 3 echo "fastspar --otu_table ${outp}.bootstrap_counts/{/} --correlation ${outp}.bootstrap_correlation/{/} --covariance ${outp}.bootstrap_correlation/cor_{/} -i 5 --threads 10  -y"  > ${outp}.r2.sh;
parallel -j 40 < ${outp}.r2.sh;

fastspar_pvalues -t 60 --otu_table  $inf --correlation ${outp}.correlation.tsv --prefix ${outp}.bootstrap_correlation/cor_x_ --permutations 1000 --outfile ${outp}.pval.tsv

rm ${outp}.r2.sh ${outp}.r1.sh;
