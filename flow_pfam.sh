( [ $# -ne 3 ] ) && echo "$0 <fasta> <out_dir> <out_prefix>" && exit 127
inf=`realpath $1`
outd=`realpath $2`
pref=$3

shopt -s expand_aliases

#-----------------------
#        software
[ -f "/usr/local/bin/pigz" ] && alias gzip="/usr/local/bin/pigz" ||  alias gzip="/usr/bin/gzip"

#-----------------------
#        database
database=/share/data1/Database/Pfam/releases35/


if ( [[ $inf =~ ".gz$" ]] )
then
    gzip -dc  $inf > ${outd}/${pref}.temp.faa
elif ( [[ $inf =~ ".bz2$" ]] )
then
    bunzip2 -dc $inf > ${outd}/${pref}.temp.faa
else
    ln -s $inf  ${outd}/${pref}.temp.faa
fi

export PERL5LIB=/share/data1/software/PfamScan:/root/perl5/lib/perl5:$PERL5LIB

/usr/bin/perl /share/data1/software/PfamScan/pfam_scan.pl -cpu 10 \
    -dir ${database} -as  \
    -fasta ${outd}/${pref}.temp.faa \
    -outfile ${outd}/${pref}.pfam \
    && rm ${outd}/${pref}.temp.faa
