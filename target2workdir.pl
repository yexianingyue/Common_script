#!/usr/bin/perl
#===============================================================================
#
#         FILE: target2workdir.pl
#
#        USAGE: ./target2workdir.pl
#
#  DESCRIPTION:
#
#      OPTIONS: ---
# REQUIREMENTS: ---
#         BUGS: ---
#        NOTES: ---
#       AUTHOR: ZHOU Yuanjie (ZHOU YJ), libranjie@gmail.com
# ORGANIZATION: R & D Department
#      VERSION: 1.0
#      CREATED: Thu May 25 11:57:36 2017 CST
#     REVISION: ---
#===============================================================================
use strict;
use warnings;
use utf8;
use Getopt::Std;

#===============================================================================
our ( $opt_i, $opt_d, $opt_e, $opt_h );

#===============================================================================
my $Version = "Thu May 25 11:57:36 2017 CST";
my $Contact = "ZHOU Yuanjie (ZHOU YJ), libranjie\@gmail.com";

#===============================================================================
&usage if ( 0 == @ARGV );
&usage unless ( getopts('i:d:eh') );
&usage if ( defined $opt_h );
unless ( 0 == @ARGV ) {
  &usage("with undefined options: @ARGV");
}
&usage("lack project abbreviation name with: -i") unless ( defined $opt_i );
&usage("lack project main directory with: -d")    unless ( defined $opt_d );

#===============================================================================
my @analysis = (
  "data",
);

#===============================================================================
my ( $abbr, $workdir, $execute );
$abbr    = &format_abbreviation($opt_i);
$workdir = $opt_d;
$workdir =~ s/\/$//g;
$execute = ( defined $opt_e ) ? 1 : 0;
&usage("project main directory must pre existed: $opt_d $!")
  unless ( -d $opt_d );
&target2workdir( $abbr, $workdir, $execute );

#===============================================================================
sub target2workdir {
  my ( $abbr, $workdir, $execute ) = @_;
  my ( $target, $year, $date, $i );
  &versionByDate( \$year, \$date );
  $target = $year . "." . $abbr;
  $target =~ s/-\d$//;
  if ($execute) {
    &submkdir("$workdir/$target");
  }
  else {
    print "mkdir -p $workdir/$target\n";
  }
  $target .= "/" . $date . "." . $abbr;
  if ($execute) {
    &submkdir("$workdir/$target");
  }
  else {
    print "mkdir -p $workdir/$target\n";
  }

  foreach $i (@analysis) {

    if ($execute) {
      &submkdir("$workdir/$target/$i");
    }
    else {
      print "mkdir -p $workdir/$target/$i\n";
    }
  }
}

#===============================================================================
sub format_abbreviation {
  my ($abbr) = @_;
  #$abbr = uc($opt_i);
  $abbr =~ s/\s+/-/g;
  $abbr =~ s/\{//g;
  $abbr =~ s/\}//g;
  $abbr =~ s/\[//g;
  $abbr =~ s/\]//g;
  $abbr =~ s/\(//g;
  $abbr =~ s/\)//g;
  $abbr =~ s/\<//g;
  $abbr =~ s/\>//g;
  $abbr =~ s/\'//g;
  $abbr =~ s/\,//g;
  $abbr =~ s/\?//g;
  print STDERR "change project abbreviation from $opt_i to $abbr\n"
    unless ( $opt_i eq $abbr );
  return $abbr;
}

#===============================================================================
sub versionByDate {
  my ( $year, $date ) = @_;
  my ( $time, @info );
  $time = localtime;
  @info = split /\s+/, $time;
  $info[3] =~ s/^(\d+):(\d+):\d+/$1.$2/;
  $$year = $info[-1];
  $$date = "$info[-1].$info[1]$info[2]";
}

#===============================================================================
sub submkdir {
  my ($subdir) = @_;
  mkdir $subdir, 0755 or die "mkdir $subdir $!\n" unless ( -d $subdir );
}

#===============================================================================
sub usage {
  my ($reason) = @_;
  print STDERR "
  ==============================================================================
  $reason
  ==============================================================================
  " if ( defined $reason );
  print STDERR "
  Version: $Version
  Contact: $Contact

  Usage:
  \$perl $0 [options]
  -i  --abbr  project abbreviation, required
  -d  --dir   project main directory, required
  -e  --exe   execute with main directory, default print command
  -h  --help
  \n";
  exit;
}

#===============================================================================
