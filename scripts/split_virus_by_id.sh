#!/usr/bin/sh
set -e

if [ $# -ne 2 ];then
    echo -e "\n\tUssage:"
    echo -e "\t\t$0 \033[32minput.fa[.gz]\033[0m \033[32moutdir\033[0m"
    echo -e ""
    exit 0
fi


inf=$1
outd=$2

less $inf | awk -v outd="$outd" '/>/ { seq_count++; dir_idx = int((seq_count-1)/2000) + 1; dir=outd "/" dir_idx; f=dir "/" substr($1, 2) ".fa"; if( system("[ -d " dir " ]") != 0 ){system("mkdir -p " dir); }  } {print > f}' \
    && find $(realpath -s ${outd}/) -name "*.fa"  | perl -ne 'chomp;$_=~/.*\/(.*).fa/;print "$1\t$_\n"' > ${outd}/split.list
