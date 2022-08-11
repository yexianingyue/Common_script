# 20220811
添加了多线程下载脚本`parallel_down.sh`
修改了`R_functions`脚本当中的一些参数，以避免命名冲突
```bash
缺点就是不能自动识别名字
parallel_down.sh <./xx> 80 1000000 "https://bcb.unl.edu/dbCAN2/download/CAZyDB.08062022.fa"
```

# 常用脚本备份

```
normalization.py # 抽平reads
so # fasta report
parse_so_*.py # 转成表格
gtf2faa_zy.pl # 引文genemark——es/t 输出的名字有点怪异，所以改了一下
sam_flags.py  # 查看sam flag
TNF.py # 四核苷酸频率
find_SMGC.py # from pfam result
flow_down_jinweizhi.sh # 金唯智公司测序数据批量下载 ， 用于linux, 如果可以下载到对应的windows软件： ossutil64，亦可以批量下载
combine_file_zy_folder_allsample.py  # 合并目录下的多个文件，更据某某一列
BIONJ, JSD, FFP # 用于真菌构建进化树 https://github.com/jaejinchoi/FFP
```

