shopt -s expand_aliases

( [ $# -ne 2 ] ) && echo "<fasp_url> <out_dir>" && exit 0;


file_path=$1
file=${file_path##*/}
outd=$2

( [ -f "${outd}/${file}" ] && [ ! -f "${outd}/${file}.aspx"  ] ) && exit 0;

alias ascp='/share/data1/software/miniconda3/envs/aspera/bin/ascp'
KEY='/share/data1/software/miniconda3/envs/aspera/etc/asperaweb_id_dsa.openssh'

ascp -L - -P 33001 -v -Q -Tr -k 1 -l 500m -i $KEY \
    --mode recv era-fasp@fasp.sra.ebi.ac.uk:${file_path} ${outd}/ &

pid=$!

echo "$pid"

sleep 20;

trap 'clean_tmp' SIGINT SIGTERM
clean_tmp(){
    kill -9 $pid
}

while [ 0 -lt 1 ]
do
    ( [ ! -f "${outd}/${file}.aspx" ] )  && exit 0;

    fsize=`stat -c "%s" ${outd}/${file}`
    fdate=`stat -c %Y "${outd}/${file}.aspx"` # 获取文件修改时间
    cdate=`date +%s` # 当前时间戳
    diff_date=`echo "( $cdate - $fdate ) / 60" | bc -l`

    # 如果文件超过3分钟都没有更新，那就停止任务，开始新的
    if [[ $diff_date > 3 ]] && [ -f "${outd}/${file}.aspx" ]
    then
        kill -9 $pid
        echo $file_path | mail -s "Failed data" -r "zhangy2@download.project.id" yexianingyue@126.com;
        sleep 20
        $0 $file_path $outd
        exit 127;
    fi

    # 文件大小合适后，停止任务
    if [ $fsize -gt 1200000000 ]
    then
        kill -9 $pid;
        rm ${outd}/${file}.aspx;
        exit 0;
    fi
    sleep 5;
done
