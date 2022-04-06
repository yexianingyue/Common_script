#!/usr/bin/sh
a=`find . -name "*.partial" -type f -size +800M`
b=`find . -name "*.partial" -type f| wc -l`
reads_num=40000000
t=30 # threads
while(( $b != 0  ))
do
    if [ -f $a  ]
    then
        c=`echo $a | awk -F ".gz.partial" '{print $1}'`
        pigz -p $t -dc $a | head -n $reads_num > $c.$reads_num
        size=`wc -l $c.$reads_num | cut -d " " -f 1`
        if [ $size -ge $reads_num  ]
        then
            touch $c.gz
            rm "$c.gz.aspera-ckpt"
            pascp=`pgrep ascp`
            kill -9 $pascp
            rm $a $c.gz # 如果在处理的这段时间，文件下载完了，那就把下载好的也删了吧，反正目的已经达到了
            echo -e "I see you \\( ^ 0 ^ )/ !!!\tand I'm compressing $c.$reads_num to $c.$reads_num.gz"
            pigz -p $t $c.$reads_num
            echo "rm $a or $c.gz"
            sleep 60 # 每次删完后，会有一段时间的反应时间，所以这边可以时间放宽一点
        else
            echo "Waiting for a predestined partial file (~ v ~)"
        fi
    fi
    echo "See you in three minutes." `date`
    sleep 30
    a=`find . -name "*.partial" -type f -size +800M`
    b=`find . -name "*.partial" -type f|wc -l`
done

echo "I've done all that (^_^). Bye" `date`
