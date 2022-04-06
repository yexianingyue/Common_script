#!/usr/bin/bash

if [ $# -lt 4 ];then
    echo "$0 <fq1> <fq2> <out_prefix> <min_len>"
    echo "min_len: remove length less than <min_len>; 150 -> 90; 100bp -> 60"
    exit 0
fi

fq1=$1
fq2=$2
out=$3
len=$4

fastp  -w 4 -q 20 -u 30 -n 5 -y -Y 30  --trim_poly_g -j /dev/null -h /dev/null \
    -l $len \
    -o $out.1.fq.gz \
    -i $fq1 -I $fq2 \
    -O $out.2.fq.gz  2> $out.log

#perl -e 'open I, "$ARGV[0]";while(<I>){chomp;if($_=~/^Read1 before filtering:/){$stat=1;next};if($stat==1){$_=~/total reads: (\d+)/;$r1=$1;$stat=0; next};if($_=~/^Read1 after filtering:/){$stat=2;next}; if($stat==2){$_=~/total reads: (\d+)/;$r1a=$1; $rate=$r1a/$r1*100;print "$ARGV[0]\t$r1\t$r1a\t$rate\n";last} }'  $out.log
# print <before: total_reads> <after: total_reads> <rate> <after: q20> <after: q30>
perl -e 'open I, "$ARGV[0]";while(<I>){chomp;if($_=~/^Read1 before filtering:/){$stat=1;next};if($stat==1){if($_=~/total reads: (\d+)/){$r1=$1};if($_=~/Q20 bases: \d+\((.*)\)/){$q20=$1};if($_=~/Q30 bases: \d+\((.*)\)/){ $q30=$1;$stat=0; next}};if($_=~/^Read1 after filtering:/){$stat=2;next}; if($stat==2){if($_=~/total reads: (\d+)/){$r1a=$1; $rate=$r1a/$r1*100}elsif($_=~/Q20 bases: \d+\((.*)\)/){$q20a=$1;next}elsif($_=~/Q30 bases: \d+\((.*)\)/){$q30a=$1;print "$ARGV[0]\t$r1\t$r1a\t$rate\t$q20a\t$q30a\n";last} }}' $out.log
