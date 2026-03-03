#!/usr/bin/bash

#--------------------
# default configure

bin=/usr/local/bin
export PATH=$bin:$PATH


if [ $# -ne 2 ];then
    echo -e "\n\t$0 <genome> <output_file>"
    echo -e ""
    exit 127
fi

infa=$1
outf=$2


## 是否有程序正在运行
if [ -f ${outf}.running ];then
    exit 127;
fi


## 运行主程序
if [ ! -f ${outf} ];then
    touch ${outf}.running \
        && tRNAscan-SE  -q -L -B -o ${outf} ${infa} \
        && rm ${outf}.running
fi


## 异常终止时删除文件
clean_tmp(){
    echo "Accidental termination"
    rm ${outf}.running ${outf};
    exit 127
}

trap 'clean_tmp' SIGINT SIGTERM


