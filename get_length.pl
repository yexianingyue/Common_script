#!/usr/bin/perl
##########################################################
# Creater       :  夜下凝月
# Created  date :  2023-08-04, 11:12:38
# Modiffed date :  2023-08-04, 11:12:38
##########################################################

use warnings;
use strict;
my $doc = << "EOF";
    Usage: perl $0 <fasta> <out>
EOF

die "$doc\n" if  @ARGV != 2 or @ARGV == 0 or $ARGV[0] eq  "-h" or $ARGV[0] =~ /-help/;

my ($in_f, $out_f) = @ARGV;

die "Overlap In-Output...\n" if $in_f eq $out_f;

# 打开方式
if ($in_f =~ /\.gz$/) { 
    open IN, "gzip -dc $in_f |" or die $!;
} elsif($in_f =~ /\.bz2$/){ 
    open IN, "bzip2 -dc $in_f |" or die $!;
} else { open IN, $in_f or die $!;
}

open OT,">$out_f" or die $!;
print OT "name\ttotal\twithout_N\n"; 

my ($head, $len, $non) = ('', 0, 0);

while (<IN>) {
    chomp;

    if (/^>(\S+)/) {
        print OT "$head\t$len\t$non\n" if $len > 0;
        ($head, $len, $non) = ($1, 0, 0);
        next;
    }
    $len += length $_;
    s/N|n//g; $non += length $_;
}
print OT "$head\t$len\t$non\n" if $len > 0;
close IN;
close OT;

print STDERR "Program End...\n";
############################################################

