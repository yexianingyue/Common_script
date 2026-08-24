#!/usr/bin/bash

#--------------------
# default configure

# db_default_rfam='/share/data2/guorc/Software/infernal-1.1.4/Rfam.v14/Rfam.cm'
db_default_rfam="/share/data2/guorc/Software/infernal-1.1.4/Rfam.v14/Rfam.rRNA.cm"
bin=/share/data2/guorc/Software/infernal-1.1.4/infernal-1.1.4/bin/bin
export PATH=$PATH:$bin


if [ $# -lt 2 ] || [ $# -gt 3 ];then
    echo -e "\n\t$0 <genome> <output_file> [rfam_db]"
    echo -e "\n\trfam_db:\n\t\t${db_default_rfam}\n"
    exit 127
fi

infa=$1
outf=$2
db_rfam=${3:-${db_default_rfam}}


## 是否有程序正在运行
if [ -f ${outf}.running ];then
    exit 127;
fi


## 运行主程序
if [ ! -f ${outf} ];then
    touch ${outf}.running \
        && cmsearch -Z 1000 --hmmonly --cut_ga --noali --tblout ${outf} ${db_rfam} ${infa} > ${outf}.log \
        && rm ${outf}.running
fi


## 异常终止时删除文件
clean_tmp(){
    echo "Accidental termination"
    rm ${outf}.running ${outf};
    exit 127
}

trap 'clean_tmp' SIGINT SIGTERM


