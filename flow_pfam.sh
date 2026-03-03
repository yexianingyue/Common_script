#!/usr/bin/bash

( [ $# -ne 2 ] ) && echo "$0 <fasta> <output_file>" && exit 127

inf=`realpath -s $1`
outf=`realpath -s $2`


if [ -f "${outf}.lock" ];then
    echo "${outf} is running."
    exit 127
fi



if [ -f "${outf}.ok" ];then
    echo -e "\033[32msuccess:\033[0m\t$outf."
    exit 0
fi

shopt -s expand_aliases

#-----------------------
#        software
[ -f "/usr/local/bin/pigz" ] && alias gzip="/usr/local/bin/pigz" ||  alias gzip="/usr/bin/gzip"

#-----------------------
#        database
database=/share/data1/Database/Pfam/releases35/



touch ${outf}.lock

if ( [[ $inf =~ .gz$ ]] )
then
    gzip -dc  $inf > ${outf}.temp.faa || ! rm ${outf}.temp.faa || exit 127
elif ( [[ $inf =~ .bz2$ ]] )
then
    bunzip2 -dc $inf > ${outf}.temp.faa || ! rm ${outf}.temp.faa || exit 127
else
    ln -s $inf  ${outf}.temp.faa
fi

[ $? -ne 0 ] && exit 127

export PERL5LIB=/share/data1/software/PfamScan:/root/perl5/lib/perl5:$PERL5LIB

/usr/bin/perl /share/data1/software/PfamScan/pfam_scan.pl \
    -dir ${database} -as  \
    -fasta ${outf}.temp.faa \
    -outfile ${outf} \
    && mv ${outf}.lock ${outf}.ok \
    && chmod 444 ${outf} \
    && rm ${outf}.temp.faa
