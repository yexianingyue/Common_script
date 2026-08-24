## 202604

### 改
1. besthist.cazy.py  
2. flow_fastp.sh ## 自动过滤长度  
3. flow.virus.genomad.sh ## 质粒鉴定结果  
4. flow.qc.fastp.sh  ## 将flow_fastp.sh重构  
5. 修改了PCoA，使其默认正方形


### 增
1. flow_fastspar.sh  ## sparcc的脚本，只不过提供的表格需要提前生成好  
2. flow.qc.rmhost.sh ## 使用bowtie2去宿主，主要是可以根据测试的map rate来自动选择是否去宿主
3. tools_get_identity_from_samfile.py ## 获取sam文件中，比对的相似度



> 修复bug


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

