#!/usr/bin/perl
use warnings;
use strict;

my $doc = << "EOF";
    
    >>>>>
    解析这个软件出来的结果
    cmsearch --cpu <threads> -Z 1000 --hmmonly --cut_ga --noali --tblout <rRNA.result> <rfam_database> <input_fasta>
    <<<<<

    perl $0 <rRNA.result> <name>

EOF

die "$doc\n" if  @ARGV == 0 or $ARGV[0] eq  "-h" or $ARGV[0] =~ /-help/ or @ARGV != 2;

my ($ssu, $lsu, $s5, $all) = (0, 0, 0, 0);
my ($inf, $name) = ($ARGV[0], $ARGV[1]);

open IN, $inf or die $!;
while(<IN>){
    chomp;
    next if /^#/;
    $lsu = 1 if /LSU_rRNA_[ab]/;
    $ssu = 1 if /SSU_rRNA_[ab]/;
    $s5  = 1 if /5S_rRNA/;
}
close(IN);

print "$name\t$lsu\t$ssu\t$s5\n";
