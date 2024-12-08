#!/usr/bin/perl
#-------------------------------------------------
# Alex Lomsadze
# December 23, 2008
# Update January 27, 2009
# Update December 2015
# alexl@gatech.edu
# GaTech, Atlanta, GA
#
# Phase definition of GTF as in standard of GTF
#
# Input: gene coordinates in GTF format and sequence in FASTA format
# Output: nucleotide and protein sequences of genes
#-------------------------------------------------

use strict;
use warnings;

my $usage = << "EOF";
Usage:  <GTF>  <FASTA[.gz]> <out_prefix> [seq_name_prefix]
        在gtf中，CDS所在的行, 基因名字必须可以被 gene_id "xxx_g"匹配到
EOF

if ( scalar(@ARGV) != 3 ) { print $usage; exit(0); }

my %genes; # {"gene_id": ['ctg_id',+/- phase start end phase1 start1 end1 phase2 start2 end2 ......], 'gene_id2': [....] }
my %sequence;
my %nuc;
my %prot;
my @seq_order; # 储存基因的顺序
my $compress=system("which pigz > /dev/null 2>&1") == 0 ? 'pigz': 'gzip';
my $file_type= $ARGV[1] =~ /.gz$/ ? "gz" : "file";
my $seq_prefix= scalar(@ARGV) == 4 ? $ARGV[3] : "";

ReadGTF( $ARGV[0] );
ReadSequence( $ARGV[1] );
# foreach my $k (keys %genes){ print ("$k\n".join(" ", @{$genes{$k}})."\n"); last; exit 0;} # debug genes
# foreach my $k(@seq_order){print "$k\n";last;exit 0} # debug seq_order

# to do &CheckSeqIdConsistency();

my %tranaa;
FillTranaa();

GetNucleotide(); # 之后，genes会变成序列，{'id':'NKAKLDURK...', }
GetProtein();
# foreach my $k (keys %nuc){ print ("$k\n");die("debug");} # debug nuc
# foreach my $k(@seq_order){print "$k\n";last;exit 0} # debug seq_order

PrintNuc( "$ARGV[2].ffn", $seq_prefix);
PrintProt( "$ARGV[2].faa", $seq_prefix);

#------------------------------------------------
sub ReadGTF
{
  my ($name) = @_;
  if ( $name =~ /.gz/ ){
      open( IN, "$compress -dc $name|" ) || die "$! on open $name\n";
  }else{
      open( IN, $name ) || die "$! on open $name\n";
  }

  my $seq_id;
  my $type;
  my $left;
  my $right;
  my $strand;
  my $phase;
  my $gene_id;

  while(<IN>)
  {
#            1          2      3      4             5      6                  7
#          seq_id      type   left   right        strand  phase            gene_id              
    next if ( /^\s+$/ );
    next if ( /^#/ );
    next if ( not /CDS/ );
    if ( /^(\S+).*?\t\S+\t(\S+)\t(\d+)\t(\d+)\t\S+\t([\+-])\t([012.])\t.*gene_id \"(\S+)\"/ )
    {
      $seq_id = $1;
      $type = $2;
      $left = $3;
      $right = $4;
      $strand = $5;
      $phase = $6;
      $gene_id = $7;

      if ( $type eq "CDS" )
      {
        if ( !defined ($genes{$gene_id}) )
        {
            push @seq_order, "$seq_id.$gene_id"; # 获取gene_id
            push @{ $genes{ $gene_id} }, $seq_id, $strand, $phase, $left, $right;
        }
        else
        {
            push @{ $genes{ $gene_id} }, $phase, $left, $right;
        }
      } 
    }
    else
    {
      die( "error in file format GTF: $_\n" );
    }
  }

  close IN;
}
#------------------------------------------------
sub ReadSequence
{
  my ($name) = @_;
  if ( $file_type eq "gz" ){
      open( IN, "$compress -dc $name|" ) or die("$! on open $name\n");
  }else {
      open( IN, $name ) || die "$! on open $name\n";
  }

  my $current = "";
  my $seq = "";
  my $line;

  while(<IN>)
  {
    if ( /^>(\S+).*/ )
    {
      if ( $current ne "" )
      {
        if ( $seq eq "" ) { die( "where is sequence?\n" ); }

	$sequence{ $current } = $seq;
      }

      $current = $1;
      $seq = "";
    }
    else
    {
      if ( $current eq "" ) { die( "error in sequence fasta format\n" ); }

      $line = uc $_;

      # remove non alphabet
      $line =~ tr/A-Z//dc;

      # move to dna characters
      $line =~ tr/U/T/;

      # replace allowed nucleic acid code (non A T C G) by N
      $line =~ tr/RYKMSWBDHV/N/;

      # stop if unexpected character
      if ( $line =~ m/[^ATCGN]/ )
        { die "unexpected letter in sequence\n"; }

      $seq .= $line;
    }
  }

  # copy from while loop - not nice
  if ( $current ne "" )
  {
    if ( $seq eq "" ) { die( "where is sequence?\n" ); }
    $sequence{ $current } = $seq;
  } 

  close IN;
}
#------------------------------------------------
sub GetNucleotide
{
  my @all_id = keys %genes;
  my $size;
  my $seq;
  my $seqId;
  my $exonCount;
  my $length;

  foreach my $i ( @all_id )
  {
    $seq = "";
    $seqId = $genes{$i}[0];

    $size = scalar( @{ $genes{$i} } );    
    $exonCount = ($size - 2)/3 ;

    if ( ($size - 2)%3 != 0 ) { die; }
    if ( $exonCount < 1 ) { die; }

    for( my $j = 0; $j < $exonCount; ++$j )
    {
      $seq .= substr( $sequence{$seqId}, $genes{$i}[ 3*$j + 2 + 1 ] - 1, $genes{$i}[ 3*$j + 2 + 2 ] - $genes{$i}[ 3*$j + 2 + 1 ] + 1 );
    } 

    if ( $genes{$i}[1] eq "+" )
    {
      if ( $genes{$i}[2] == 1 )
      {
        $seq =~ s/^.//;
      }
      elsif ( $genes{$i}[2] == 2 )
      {
        $seq =~ s/^..//;
      }
      elsif ( $genes{$i}[2] == 0 ) { ; }
      else { die; }

      $length = length( $seq );

      if ( $length%3 == 1 )
      {
        chop $seq;
      }
      elsif ( $length%3 == 2 )
      {
        chop $seq;
        chop $seq;
      } 
      elsif ( $length%3 == 0 ) { ; }
      else {die; }

      if ( length( $seq ) % 3 != 0 ) { die"$i"; }
    } 

    if ( $genes{$i}[1] eq "-" )
    {
      if ( $genes{$i}[ $size - 3 ] == 1 )
      {
        chop $seq;
      }
      elsif ( $genes{$i}[ $size - 3 ] == 2 )
      {
        chop $seq;
	chop $seq;
      }
      elsif ( $genes{$i}[ $size - 3 ] == 0 ) { ; }
      else { die; }

      $seq = &RevComp( $seq );

      $length = length( $seq );
      if ( $length%3 == 1 )
      {
        chop $seq;
      }
      elsif ( $length%3 == 2 )
      {
        chop $seq;
        chop $seq;
      }
      elsif ( $length%3 == 0 ) { ; }
      else {die; }

      if ( length( $seq ) % 3 != 0 ) { die"$i"; }
    }

    $nuc{ "$seqId.$i" } = $seq; # modiff by zhangy2
  }
}
#------------------------------------------------
sub GetProtein
{
  my $seq;

  foreach my $i ( @seq_order )
  {
    $seq = &dna_to_aa( $nuc{$i} );
    if ( $seq =~ /\*$/ )
    {
       chop $seq;
    }
    $prot{$i} = $seq;
  }
}
#------------------------------------------------
sub RevComp
{
  my ($s) = @_;
  $s =~ s/T/1/g;
  $s =~ s/C/2/g;
  $s =~ s/A/T/g;
  $s =~ s/G/C/g;
  $s =~ s/1/A/g;
  $s =~ s/2/G/g;
  $s = reverse($s);
  return $s;
}
#------------------------------------------------
# this sub is modification of code from John Besemer (2000 GaTech)
sub FillTranaa
{
    $tranaa{"TTT"}="F";  $tranaa{"TTC"}="F"; $tranaa{"TTA"}="L"; $tranaa{"TTG"}="L";
    $tranaa{"CTT"}="L";  $tranaa{"CTC"}="L"; $tranaa{"CTA"}="L"; $tranaa{"CTG"}="L";
    $tranaa{"ATT"}="I";  $tranaa{"ATC"}="I"; $tranaa{"ATA"}="I"; $tranaa{"ATG"}="M";
    $tranaa{"GTT"}="V";  $tranaa{"GTC"}="V"; $tranaa{"GTA"}="V"; $tranaa{"GTG"}="V";
    $tranaa{"TCT"}="S";  $tranaa{"TCC"}="S"; $tranaa{"TCA"}="S"; $tranaa{"TCG"}="S";
    $tranaa{"CCT"}="P";  $tranaa{"CCC"}="P"; $tranaa{"CCA"}="P"; $tranaa{"CCG"}="P";
    $tranaa{"ACT"}="T";  $tranaa{"ACC"}="T"; $tranaa{"ACA"}="T"; $tranaa{"ACG"}="T";
    $tranaa{"GCT"}="A";  $tranaa{"GCC"}="A"; $tranaa{"GCA"}="A"; $tranaa{"GCG"}="A";
    $tranaa{"TAT"}="Y";  $tranaa{"TAC"}="Y"; $tranaa{"TAA"}="*"; $tranaa{"TAG"}="*";
    $tranaa{"CAT"}="H";  $tranaa{"CAC"}="H"; $tranaa{"CAA"}="Q"; $tranaa{"CAG"}="Q";
    $tranaa{"AAT"}="N";  $tranaa{"AAC"}="N"; $tranaa{"AAA"}="K"; $tranaa{"AAG"}="K";
    $tranaa{"GAT"}="D";  $tranaa{"GAC"}="D"; $tranaa{"GAA"}="E"; $tranaa{"GAG"}="E";
    $tranaa{"TGT"}="C";  $tranaa{"TGC"}="C"; $tranaa{"TGA"}="*"; $tranaa{"TGG"}="W";
    $tranaa{"CGT"}="R";  $tranaa{"CGC"}="R"; $tranaa{"CGA"}="R"; $tranaa{"CGG"}="R";
    $tranaa{"AGT"}="S";  $tranaa{"AGC"}="S"; $tranaa{"AGA"}="R"; $tranaa{"AGG"}="R";
    $tranaa{"GGT"}="G";  $tranaa{"GGC"}="G"; $tranaa{"GGA"}="G"; $tranaa{"GGG"}="G";
}
#------------------------------------------------
sub dna_to_aa {
    #usage:  $aminoacidsequence = &dna_to_aa($DNAsequence);
    #output: translated sequence
    my($DNAsequence)=@_;
    my($aminoacidsequence, $codon, $i);
    
    $aminoacidsequence="";

    for ($i=0; $i<length($DNAsequence); $i += 3)
    {
        $codon = substr($DNAsequence, $i ,3);

		if ( !defined $tranaa{$codon} )
		{
			print $codon ."\n";
			$tranaa{$codon} = '';
		}

        if ($tranaa{$codon} eq '')
        {
        	$aminoacidsequence .= "X";
        }
        else 
        {
        	$aminoacidsequence .= $tranaa{$codon};
        }
    }
    
    return $aminoacidsequence;
}
#------------------------------------------------
sub PrintGenes
{
  my @all_id = keys %genes;

  foreach my $i ( @all_id )
  {
     print "$i: @{ $genes{ $i } }\n"
  }
}
#------------------------------------------------
sub PrintSequence
{
  my @all_id = keys %sequence;

  foreach my $i ( @all_id )
  {
    print "$i:  $sequence{ $i }\n"
  }
}
#------------------------------------------------
sub PrintNuc
{
  my ($name, $pname) = @_;

  if ( defined $name )
  {
      if ( $file_type eq "gz" ){
          open( OUT, "| $compress > $name.gz" ) or die("$! , error on open file $name\n");
      }else {
          open( OUT, ">$name" )||die( "$!, error on open file $name" );
      }
    foreach my $i ( @seq_order )
    {
      print OUT ">$pname$i\n"; # modiff
      print OUT $nuc{ $i } ."\n"
    }
    close OUT;
  }
  else
  {
    foreach my $i ( @seq_order )
    {
      print ">$pname$i\n";
      print $nuc{ $i } ."\n"
    }
  }
}
#------------------------------------------------
sub PrintProt
{
  my ($name,$pname) = @_;

  if ( defined $name )
  {
      if ( $file_type eq "gz"){
          open( OUT, "| $compress > $name.gz" ) or die("$! , error on open file $name\n");
      }else {
          open( OUT, ">$name" )||die( "$!, error on open file $name" );
      }
    foreach my $i ( @seq_order )
    {
      print OUT ">$pname$i\n";
      print OUT $prot{ $i } ."\n"
    }
    close OUT;
  }
  else
  {
    foreach my $i ( @seq_order )
    {
      print ">$pname$i\n";
      print $prot{ $i } ."\n"
    }
  }
}
#------------------------------------------------

