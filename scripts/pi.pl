#!/usr/bin/perl
use warnings;
use strict;

my $doc = << "EOF";
过滤条件参考：
Marine DNA Viral Macro- and Microdiversity from Pole to Pole
过滤规则大致如下：
    1、位点覆盖总深度 >= 10x      // MinDepth
    2、等位基因至少有4个碱基支持  // min allel
    3、突变频率 5%                // Variable frequency
计算核酸微观多样性, 而且非参考基因等位基因个数，正负链相加至少为4个
DP=， 作者说代表的真实深度，I16代表的是-Q过滤后的个数

perl $0 <vcf file> <MinDepth|10> <Variable frequency|0.05> <min_allel|4> > stdout
EOF

die "$doc\n" if  @ARGV > 4 or @ARGV == 0 or $ARGV[0] eq  "-h" or $ARGV[0] =~ /-help/;
my ($in_f, $MIN_DP, $MIN_CONS, $MIN_ALLEL) = ($ARGV[0], $ARGV[1]||10, $ARGV[2]||0.05, $ARGV[3]||4);
my ($s, $total_mutation_site, $allel, $dp, $cons, $total_dp, $total_allel) = (0, 0, 0, 0, 0, 0, 0);
open IN, $in_f or die $!;

while(<IN>){
	chomp;
	my @l = split/\s+/;
	next if $_ =~ /^##|^#CHROM|INDEL;IDV=/;
	$_ =~ /DP=(\d+);I16=(\d+),(\d+),(\d+),(\d+)/;
	next if $1 < $MIN_DP;
    $dp = $2 + $3 + $4 + $5;
	$allel = $4 + $5;
	$total_mutation_site++;
	# 条件过滤
	next if $dp < $MIN_DP || $allel < 4 || $allel/$dp < $MIN_CONS;
	$total_allel += $allel;
	$total_dp += $dp;
	$s += ($2 + $3)/$dp * $allel/($dp-1);
}
print "file: $in_f\ttotal var: $total_mutation_site\ts: $s\ttotal allel: $total_allel\ttotal_DP: $total_dp\n"
