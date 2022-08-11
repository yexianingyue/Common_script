#!/usr/bin/bash

# 先利用curl -I -s 参数，获取下载文件的大小
# 然后再利用curl -r 参数下载文件的指定字节段。这个过程就可以使用多线程进行下载
# 缺点就是必须自己命名才行

if [ $# -lt 4 ];then
    echo "$0 <out_file> <threads> <block_size:bytes> <url>"
    exit 127
fi

out_f=$1
threads=$2
size_split=$3 # 就是文件将分为多大的块进行逐个下载
url=$4
if [ -f $out_f ];then
    echo "${out_f} is exists."
    exit 127
fi

temp_dir=${out_f}_$$  # $$ is pid of this script 
file_size=`curl -I -s  ${url} | perl -ne 'if (/Content-Length:\s+(\d+)/){print "$1";last}'`  #获取文件的具体大小 byte

mkdir ${temp_dir};
perl -e 'foreach ($i=0; $i<=$ARGV[0]; $i+=$ARGV[1]){$s=$i+1; $s=0 if $i == 0; $e=$i+$ARGV[1];$e=$ARGV[0] if $e > $ARGV[0];print "$s\-$e\n"}'  ${file_size} ${size_split} > ${temp_dir}/sp.list 
parallel -j ${threads} --joblog ${temp_dir}/parallel.log  curl -r {} -o ${temp_dir}/{\#}  ${url} :::: ${temp_dir}/sp.list ;

nfiles=`cat ${temp_dir}/sp.list| wc -l`;
# 如果上步出错，就重试10次，间隔5秒
count_=0
while [ $? -ne 0 ]
do
    $count+=1
    sleep 5
    parallel --retry-failed --joblog ${temp_dir}/parallel.log ;
    if [ $count -lt 10 ];then
        echo "faild"
        echo "Log file: ${temp_dir}/parallel.log"
        echo "You Can run: parallel --retry-failed --joblog ${temp_dir}/parallel.log to retry downolad"
        echo "And then run : for i in \`seq 1 $nfiles\`;do cat ${temp_dir}/$i >> ${out_f};done   to combine."
        exit 127
    fi
done
touch ${out_f};
for i in `seq 1 $nfiles`;do cat ${temp_dir}/$i >> ${out_f};done

# curl -I -s  "https://data.ace.uq.edu.au/public/gtdb/data/releases/release207/207.0/auxillary_files/gtdbtk_r207_v2_data.tar.gz"  | grep Content-Length | cut -f 2 -d " " 
