#!/usr/local/bin/Rscript
library(argparse)

#Matrix reads profile # 抽平每个样本的reads数目
#Num 样本中reads数的最小值


parser <- ArgumentParser()
parser$add_argument("-i", help = "intput")
parser$add_argument("-n", help = "num of reads")
parser$add_argument("-o", help = "output")
args <- parser$parse_args()

in_file = args$i
num = as.numeric(args$n)
out = args$o

library(vegan)
RandomMatrix = function(Matrix,Num){
  Min=Num
  #tab = data.frame(x=row.names(Matrix),stringsAsFactors = F)
  tab = data.frame(x=1:nrow(Matrix),stringsAsFactors = F)
  for (x in 1:ncol(Matrix)) { #一个循环抽平一个样本
    ff = rep(1:nrow(Matrix),Matrix[,x])
    set.seed(11)  #尽量使抽样的分布一致
    ff = plyr::count(sample(ff,size=Min,replace = F)) #统计随机抽样的结果
    colnames(ff)[2] = colnames(Matrix)[x] #把列名改成样本名
    tab = merge(tab,ff,by = 'x',all = T) #把表格合并在一起
    print(x)
  }
  row.names(tab) = row.names(Matrix)[tab$x] 

  tab = tab[,-1] #删除数字列
  tab[is.na(tab)] = 0 
  return(tab)
}

dt = read.table(in_file, header=T, row.names=1, check.names=F, quote="", comment.char = "")
result = RandomMatrix(dt, num)
write.table(result, out, sep="\t", quote=F)


