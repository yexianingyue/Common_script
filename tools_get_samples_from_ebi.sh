#!/usr/bin/bash

( [ $# -ne 2 ] || [[ $1 =~ "-h" ]] ) && echo "$0 <Project> <output>" && exit 1

proj=$1
out=$2
sample_limit=20000
urls="https://www.ebi.ac.uk/ena/portal/api/filereport?result=read_run&accession=${proj}&limit=${sample_limit}&format=json&fields=study_accession,secondary_study_accession,sample_accession,secondary_sample_accession,experiment_accession,run_accession,submission_accession,tax_id,scientific_name,instrument_platform,instrument_model,library_name,nominal_length,library_layout,library_strategy,library_source,library_selection,read_count,base_count,center_name,first_public,last_updated,experiment_title,study_title,study_alias,experiment_alias,run_alias,fastq_bytes,fastq_md5,fastq_ftp,fastq_aspera,fastq_galaxy,submitted_bytes,submitted_md5,submitted_ftp,submitted_aspera,submitted_galaxy,submitted_format,sra_bytes,sra_md5,sra_ftp,sra_aspera,sra_galaxy,sample_alias"

wget --timeout 20 --tries 10 --waitretry=5 -O ${out} $urls 2> /dev/null

while [ 0 -lt 1 ]
do
    if [ $? -ne 0 ]
    then
        wget --timeout 20 --tries 10 --waitretry=5 -O ${out} $urls 2> /dev/null
    else
        exit 0
    fi
done
