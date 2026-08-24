use Getopt::Long;
use Pod::Usage;

my $data   = "file.dat";
my $length = 24;
my $verbose;
my $help = 0;

GetOptions(
    "help|h"   => \$help,
    'length|l=i' => \$length,
    'data|i=s'   => \$data,
    'verbose|v'  => \$verbose
) or pod2usage(2);

pod2usage(1) if $help;

print "$data\t$length\n";
die '';
print "query\tidentity\tcover_length\tmatch_counts\tref_length\n";
while(<>){
    next if/^@/;chomp;@l=split/\t/;
    next if ($l[1] & 0x4) != 0;
    $ref_length=0;
    $match_counts=0;
    $cov_length=0;
    while($l[5]=~/(\d+)[M=XID]/g){
        $cov_length+=$1
    }
    while($l[5]=~/(\d+)[MDN=X]/g){$ref_length+=$1};
    foreach $k(@l[11..$#l]){
        if($k=~/MD:Z:/){
            while($k=~/(\d+)/g){
                $match_counts+=$1
            }
        }
    }
    $identity=$match_counts/$cov_length*100;
    print "$l[0]\t$identity\t$cov_length\t$match_counts\t$ref_length\n";
}



__END__

=head1 NAME

myscript.pl - My script

=head1 SYNOPSIS

myscript.pl [options]

Options:
    -h, --help      show this help message

=head1 DESCRIPTION

This script does something.

=cut
