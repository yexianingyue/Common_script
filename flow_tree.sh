#!/usr/bin/bash
##########################################################
# Creater       :  夜下凝月
# Created  date :  2023-11-07, 14:58:49
# Modiffed date :  2023-11-07, 14:58:49
##########################################################


( [ $# -lt 1 ] || [ $# -gt 3 ] ) && echo -e "\n\t<<\033[32mPhylophlan.1.0\033[0m>>\n\n\tUsage:\n\n\t\t$0 <\033[32moutput_prefix\033[0m> <\033[32minput_fold\033[0m> [\033[32mncpus\033[0m]\n\n" && exit 0;

#-------------------------------------
#           Opt

conda_env=/share/data1/software/miniconda3/envs/py27
usearch5=/share/data1/software/usearch5/usearch # /path/to/usearch   ## v.5
base_dir="/share/data1/software/phylophlan-1.0/"


#-------------------------------------
#           检查依赖
for d in ${base_dir}/{input,output,data};do
    if [ ! -w $d ];then
        echo -e "这几个目录权限需要管理员改成1777, 命令如下：\n\n\tchmod 1777 ${base_dir}/{input,output,data}\n"
        exit 127
    fi
done


source activate $conda_env || ! echo -e "\n\033[31mNot Found conda env:\033[0m\n\t\t$conda_env" || exit 127
[ ! -f $usearch5 ] && echo -e "\n\033[31mNot Found software:\033[0m\t$usearch5\n" && exit 127


#-------------------------------------
#           解析参数
outd=`realpath $1`
ind=`realpath -s $2`
cpus=${3:-40}


#-------------------------------------
#   为了防止重名，需要添加一些后缀
md5=`realpath $ind| md5sum | cut -f 1 -d " "`
ind_base_name=$USER.`date +%Y%m%d`.`echo ${ind##*/}`.$md5



( [ -d "${base_dir}/input/${ind_base_name}" ] ) && rm ${base_dir}/input/${ind_base_name}
( [ -d "${base_dir}/data/${ind_base_name}" ] ) && rm -r ${base_dir}/data/${ind_base_name}
( [ -d "${base_dir}/output/${ind_base_name}" ] ) && rm -r ${base_dir}/output/${ind_base_name}


ln -s $ind ${base_dir}/input/${ind_base_name}
cd ${base_dir}


export PATH=${base_dir}/depend_software/:${usearch5%/*}:$PATH

${base_dir}/phylophlan.py \
    -u ${ind_base_name} \
    --nproc ${cpus} \
    && mv ${base_dir}/output/${ind_base_name}/${ind_base_name}.tree.nwk ${outd}.nwk \
    && mv ${base_dir}/output/${ind_base_name}/${ind_base_name}.tree.reroot.xml ${outd}.reroot.xml \
    && rm -r ${base_dir}/data/${ind_base_name} \
    && rm -r ${base_dir}/output/${ind_base_name} \
    && rm ${base_dir}/input/${ind_base_name}




 
#-----------------------------------
#   如果意外停止了，就执行xxx
trap 'clean_tmp' SIGTERM SIGINT
clean_tmp(){
    rm -r ${base_dir}/data/${ind_base_name}
}



