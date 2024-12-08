#!/usr/bin/perl -l
##########################################################
# Creater       :  夜下凝月
# Created  date :  2023-09-02, 09:53:47
# Modiffed date :  2023-09-02, 09:53:47
##########################################################

use warnings;
use strict;
my $doc = << "EOF";
perl $0 option [input.fna]
By default, obtained seq from stdin.
    rev  -> reverse seq
    revc -> reverse completement seq
    com  -> completement seq

example:
    echo "ATCGA" | $0 rev
EOF

die "$doc\n" if  @ARGV == 0 or @ARGV > 2 or @ARGV == 0 or $ARGV[0] eq  "-h" or $ARGV[0] =~ /-help/;

#------------------------------------------
sub rev_str{
    my $x = reverse $_[0];
    print $x;
}

sub rev_complete_str{
    $_[0] =~ tr/ATCG/TAGC/;
    my $x = reverse $_[0];
    print $x;
}

sub complete_str{
    $_[0] =~ tr/ATCG/TAGC/;
    print $_[0]
}

#------------------------------------------


my $opt = $ARGV[0];

shift @ARGV; # 跳过第一个元素，因为是子命令
my %myfunc = (
    "rev"   => \&rev_str,
    "revc"  => \&rev_complete_str,
    "com"   => \&complete_str
);

while (<>) {
    chomp;
    if ($_=~/^>/){
        print $_;
    }else{
        $myfunc{$opt} -> (uc($_));
        # $myfunc{$opt}(uc($_)); # 效果一样，只不过上面的更清晰一点
    }
}


