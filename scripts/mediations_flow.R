#!/usr/bin/Rscript
library(argparse)

get_args <- function(){
    parser <- ArgumentParser()
    parser$add_argument("-i", default=NULL, help = "profile. 行为物种，列为样本")
    parser$add_argument("-y", help = "应变量")
    parser$add_argument("-x", help = "自变量")
    parser$add_argument("-m", help = "中间变量")
    parser$add_argument("--sims", default=100, help = "中间变量")
    parser$add_argument("-o", help = "output file")
    parser$add_argument("-T", help = "是否对输入的矩阵转置.默认:0,不转置", default="0")
    parser
}

parser = get_args()
args = parser$parse_args()
if(is.null(args$i)){
    parser$print_help()
    quit("no", status=127)
}

# 必要参数

in_f = args$i # in_f = "../00.data/virus.profile.norm.family"
x = args$x
y = args$y
m = args$m
out_f = args$o

# 可选参数
isT = args$T
sims = as.integer(args$sims)

source("/share/data1/zhangy2/scripts/R_my_functions/zy_mediation.R")

dt = read.table(in_f, sep="\t", header=T, check.names=F, row.names=1, comment.char = "")

if(isT != "0"){
    dt = t(dt)
}

res = zy_mediation(dt, x, y, m, sims)
write.table(res,out_f, sep="\t", col.names=T, row.names=F)
