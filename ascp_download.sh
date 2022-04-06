if [ $# -lt 2 ];then
    echo "$0 <filelist> <outdir>"

    echo "<filelist> format:"
    echo "                  /vol1/fastq/ERR201/001/ERR2017411/ERR2017411_1.fastq.gz"
    exit 127
fi

list=$1
outdir=$2

if [ ! -f $list.done ];then
    touch $list.done
fi

/home/zhangy2/.aspera/connect/bin/ascp \
    -L - -P 33001 -v -Q -Tr -k 1 -l 400m -i /home/zhangy2/.aspera/connect/etc/asperaweb_id_dsa.openssh --mode recv --host fasp.sra.ebi.ac.uk --user era-fasp \
    --file-list $list $outdir > $list.log 2>&1 

while [ $? -ne 0 ]
do
    grep -wvf $list.done $list > $list.temp
    echo "continue"
    if [ ! -s $list.temp ];then
        echo 'well done \( ^ u ^ )/ '
        exit 0
    fi
    /home/zhangy2/.aspera/connect/bin/ascp \
        -L - -P 33001 -v -Q -Tr -k 1 -l 400m -i /home/zhangy2/.aspera/connect/etc/asperaweb_id_dsa.openssh --mode recv --host fasp.sra.ebi.ac.uk --user era-fasp \
        --file-list $list.temp $outdir > $list.log 2>&1 
done
