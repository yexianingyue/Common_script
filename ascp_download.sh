if [ $# -lt 2 ];then
    echo -e "\n$0 <filelist> <outdir> <ebi[default] | cngb>\n"
    echo -e "filelist是一个文件，每行的内容如下,内容格式就按照下面的:\n"

    echo "/vol1/fastq/ERR201/001/ERR2017411/ERR2017411_1.fastq.gz"
    echo "/vol1/fastq/ERR201/001/ERR2017411/ERR2017411_2.fastq.gz"
    echo "/vol1/fastq/ERR201/001/ERR2017411/ERR2017412_1.fastq.gz"
    echo "/vol1/fastq/ERR201/001/ERR2017411/ERR2017412_2.fastq.gz"
    exit 127
fi

function inspect_input(){
    inf=$1
    if [ ! -f ${inf} ];then
        echo -e "\n[\e[1;5;31mERROR !!!\e[0m]:\tPlease make sure that the input \"\e[1;91m${inf}\e[0m\" is a file.\n"
        exit 127
    fi
}

list=$1
outdir=$2
db=${3:-ebi}
inspect_input $list


user=`echo $USER`
pat=`realpath $2`


if [ ! -f $list.done ];then
    touch $list.done
fi

# 判断是否已存在同名的文件
if [ -f $outdir ];then
    echo "Error: $outdir is not a directory.";
    exit 0;
fi

# 如果没有目录，则创建
if [ ! -d $outdir ];then
    mkdir -p $outdir
fi

### default
KEY=/share/data1/software/miniconda3/envs/aspera/etc/asperaweb_id_dsa.openssh
ASCP="/share/data1/software/miniconda3/envs/aspera/bin/ascp -L - -P 33001 -v -Q -Tr -k 2 -l 400m --mode recv "

### EBI
user_ebi="era-fasp"
host_ebi="fasp.sra.ebi.ac.uk"
cmd="$ASCP -i $KEY --host ${host_ebi} --user ${user_ebi} "

### cngb
user_cngb="aspera_download"
host_cngb="183.239.175.39"
cngb_key="/share/data1/software/miniconda3/envs/aspera/etc/asperaweb_id_dsa.openssh.cngb"

if [ $db == "cngb" ];then
    cmd="$ASCP -i ${cngb_key} --host ${host_cngb} --user ${user_cngb} "
fi


echo "$user@$HOSTNAME:$pat" | mail -s "download data" -r "zhangy2@download.project.id" yexianingyue@126.com

$cmd --file-list $list $outdir > $list.log 2>&1 

while [ $? -ne 0 ]
do
    grep -wvf $list.done $list > $list.temp
    echo "continue"
    if [ ! -s $list.temp ];then
        echo 'well done \( ^ u ^ )/ '
        exit 0
    fi
    $cmd --file-list $list.temp $outdir > $list.log 2>&1 
done

size=`du -sh $outdir`
echo "$user@$HOSTNAME:$pat    size:$size" | mail -s "download data" -r "zhangy2@download.project.id" yexianingyue@126.com
