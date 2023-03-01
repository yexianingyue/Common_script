#20230301
## 添加
`str_diff.py` 来源于网络，用于比较字符串有没有区别，因为有时候两个很相似的字符串看不出来区别，只能用程序判断了`https://www.cnblogs.com/N3ptune/p/16329835.html`
## 修改
`R_my_functions/zy_plot_ROC.R` 修复了报错`No control observation.`
`R_my_functions/zy_PCoA.R` 修复Bug: 更换x,y，但是解释度并没变的问题
`combine_file_zy_folder_allsample.py` 添加了输入输出的默认参数
`ip_tool.py` 添加简单的说明
`flow_metaphlan3.sh` 无意义的修改,方便阅读
## 下期目标
完善R包的火山图


## 添加
`flow_checkv.sh` # 只是简单的跑checkv的命令，并不是流程
`randomforest_impvar_parallel.R` # 只想在外面计算它们的重要性，并进行排序 [依赖于`R_my_functions/zy_randomForest.R`]
`randomforest_ncross.R` # k-fold随机森林，这俩货每次studio跑，太麻烦. [依赖于`R_my_functions/zy_randomForest.R`]
`spearman.py` # 用于计算spearman相关性
`flow_metaphlan3.v2.sh` # 不知道为什么服务器有时候运行metaphlan时会sleep，所以直接跑bowtie2，然后再调用软件会顺利一些
## 删除
[pup](https://github.com/ericchiang/pup) 一个宣传说是对标软件[jq](https://github.com/stedolan/jq)的软件，但是一直不用，就删了
## 修复BUG
`parallel_down.sh`
`zy_composition.R`
`zy_pvalue.R`
`zy_adonis.R` # 如果某个变量去重后数量不变或为1，跳过
`zy_PCoA.R` # 将代码块中的`group_by(group=get(`group`))`改成了`group=across({{group}})`, 对于`dplyr::select(all_of(group))`,才有用, 对于mutate，使用get(`get`)
`find_fasta_from_list.py` # 添加判断参数`-e`，如果列表太长，输出未找到的列表会很话时间
## 建议
之前有被审稿人怼，说是`FFP`只是看了一下字符串相似度，并不能很好的展示遗传进化关系，所以最后找了一些标记基因，然后使用`mafft`对齐，`fasttree`画树,
画树的脚本这边就没有整理了，以后有时间再弄


# 20220912
## 添加
`tools_ncbi_parse_project.py`用于解析NCBI搜索的project页面，提取title， introduction以及文件数量的脚本

# 20220819
## 修改
`flow_fastp_rmhost.sh`, bowtie2添加了参数`--mm`,用以任务之间共享内存
`flow_megahit.v2.sh`, 组装日志内部直接重定向，不需要在外部指定了
# 20220811
添加了多线程下载脚本`parallel_down.sh`
修改了`R_functions`脚本当中的一些参数，以避免命名冲突
```bash
缺点就是不能自动识别名字
parallel_down.sh <./xx> 80 1000000 "https://bcb.unl.edu/dbCAN2/download/CAZyDB.08062022.fa"
```

# 常用脚本备份

```
ckvtk # https://github.com/shenwei356/csvtk
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

