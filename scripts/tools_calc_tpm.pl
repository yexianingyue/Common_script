#!/usr/bin/perl
##########################################################
# Creater       :  夜下凝月
# Created  date :  2023-10-25, 19:16:11
# Modiffed date :  2023-12-01, 14:34:44
##########################################################
#'''

use warnings;
use strict;
my $doc = << "EOF";

\tperl $0 <len_file> <profile> <out_f>
\tNOTE:
\t\t如果列和为0,数值将全部为0
EOF

die "$doc\n" if  @ARGV > 3 or @ARGV == 0 or $ARGV[0] eq  "-h" or $ARGV[0] =~ /-help/;

my ($lenf, $profile, $outf) = @ARGV;

## 打开方式
#if ($in_f =~ /\.gz$/) { 
#    open IN, "gzip -dc $in_f |" or die $!;
#    } elsif($in_f =~ /\.bz2$/){ 
#        open IN, "bzip2 -dc $in_f |" or die $!;
#        } else { open IN, $in_f or die $!;
#        }
#


#--------------------------------
#       get length
open I, "$lenf" or die $!;
my %len_h = ();
print "Read flen\n";
while(<I>){
    chomp;
    my ($name, $len) = (split/\t/)[0,-1];
    $len_h{$name} = $len;
}
close(I);

#--------------------------------
#       calc col sum

open I, "$profile" or die $!;
my $title = readline I;
chomp($title);
my @tmp = split /\t/, $title;
my @col_sum = (0) * scalar @tmp;

print "Calc sum\n";
while(<I>){
    print "\r$." if $. % 1000 == 0;
    chomp;
    my @l = split/\t/;
    my $gene_len =  $len_h{$l[0]};
    if ($gene_len == 0){
        die "Can't find $l[0] in $lenf\n";
    }
    foreach my $i(1..$#l){
        $col_sum[$i] += $l[$i] / $gene_len;
    }
}

my $total_len=$.;

open OT,">$outf" or die $!;

#--------------------------------
#       calc tpm
print "\nCalc tpm...\n";
seek I, 0, 0;
readline I;
print OT "$title\n";
while(<I>){
    chomp;
    my @l = split/\t/;
    print OT "$l[0]";
    my $gene_len = $len_h{$l[0]};
    print "\r$. / ${total_len}" if $. % 1000 == 0;

    foreach my $i(1..$#l){
        my $x = 0;
        if ($l[$i] != 0)
        {
            $x = ( ( $l[$i] / $gene_len) / $col_sum[$i]) * 100;
        }
        print OT "\t$x";
    }

    print OT "\n";
}

close(I);
