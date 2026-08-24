#!/usr/bin/bash
set -e

if [ $# -lt 5 ];then
    echo "$0 <AccessKeyId> <AccessKeySecret> <OSS_path[/flod]> <region> <local_dir>"
    echo "if <local_dir> not find, it will be created."
    echo "example:"
    echo "flow_down_jinweizhi.sh LTAI5tMosCYkym 8IFKYRddnUFtqlYxusc oss://ngscustomerdata/56363/ oss-cn-hangzhou ./test"
    exit 127
fi

id=$1
passwd=$2
oss=$3
region=$4
out=$5

ossutil64 \
    -u --disable-ignore-error \
    -e ${region}.aliyuncs.com \
    -i ${id} \
    -k ${passwd} \
    cp -r  \
    ${oss} \
    ${out}
