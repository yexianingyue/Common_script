#!/usr/bin/perl
##########################################################
# Creater       :  夜下凝月
# Created  date :  2023-11-03, 14:53:40
# Modiffed date :  2023-11-03, 14:53:40
##########################################################

use warnings;
use strict;
my $doc = << "EOF";

    example:
        perl $0 project.sample [projects.sample1 samples2 ... ]


    the file is download from \033[31mhttps://www.ebi.ac.uk/ena/portal/api/filereport?result=read_run&accession=PRJNA268964&limit=11&format=json&fields=study_accession,secondary_study_accession,sample_accession,secondary_sample_accession,experiment_accession,run_accession,submission_accession,tax_id,scientific_name,instrument_platform,instrument_model,library_name,nominal_length,library_layout,library_strategy,library_source,library_selection,read_count,base_count,center_name,first_public,last_updated,experiment_title,study_title,study_alias,experiment_alias,run_alias,fastq_bytes,fastq_md5,fastq_ftp,fastq_aspera,fastq_galaxy,submitted_bytes,submitted_md5,submitted_ftp,submitted_aspera,submitted_galaxy,submitted_format,sra_bytes,sra_md5,sra_ftp,sra_aspera,sra_galaxy,sample_alias\033[0m

EOF

die "$doc\n" if  @ARGV == 0 or $ARGV[0] eq  "-h" or $ARGV[0] =~ /-help/;

sub table_sample{
    # open file
    my $in_f = $_[0];
    if ($in_f =~ /\.gz$/) { 
           open IN, "gzip -dc $in_f |" or die $!;
        } elsif($in_f =~ /\.bz2$/){ 
            open IN, "bzip2 -dc $in_f |" or die $!;
        } else {
            open IN, $in_f or die $!;
    }
    while(<IN>){

        chomp;

        my $project      = $_ =~ /study_accession":"(.*?)"/ ? $1 : "false";
        my $sample       = $_ =~ /sample_accession":"(.*?)"/ ? $1 : "";
        my $runid       = $_ =~ /run_accession":"(.*?)"/ ? $1 : "";
        my $lib_strategy = $_ =~ /library_strategy":"(.*?)"/ ? $1 : "";
        my $lib_source   = $_ =~ /library_source":"(.*?)"/ ? $1 : "";
        my $lib_select   = $_ =~ /library_selection":"(.*?)"/ ? $1 : "";
        my $read_c       = $_ =~ /read_count":"(.*?)"/ ? $1 : "";
        my $base_c       = $_ =~ /base_count":"(.*?)"/ ? $1 : "";

        print "$project\t$sample\t$runid\t$lib_strategy\t$lib_source\t$lib_select\t$read_c\t$base_c\n" if $project ne "false";

    }
    close(IN)

}


print "project\tsample\trunid\tlib_strategy\tlibrary_source\tlibrary_selection\tread_count\tbase_count\n";

foreach my $f (@ARGV){
    table_sample $f;
}
