#!/usr/bin/Rscript
library(argparse)

get_args <- function(){
    parser <- ArgumentParser()
    parser$add_argument("-i", default=NULL, help = "profile")
    parser$add_argument("-g", help = "group file")
    parser$add_argument("-o", help = "output file")
    parser$add_argument("-topn", default=NULL, metavar="head species", help = "use top species")
    parser$add_argument("-sid", metavar="sample ID", default="Sample", help = "the sample id in group file (default: Sample).")
    parser$add_argument("-gid", metavar="group ID", default="Group", help = "the group id in group file (default: Group)")
    parser$add_argument("-seed", default=2022, type = "integer", help = "seed")
    parser$add_argument("-cross", default=10, type = "integer", help = "n-cross")
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
in_g = args$g # in_g = "../00.data/sample.group"
out_f = args$o

# 配置参数
sid = args$sid
gid = args$gid
nspecies = args$topn

# 可选参数
seed = as.numeric(args$seed)
cross = as.integer(args$cross)


library(dplyr, quietly = T)
source("/share/data1/zhangy2/scripts/R_my_functions/zy_randomForest.R")



dt = read.table(in_f, sep="\t", header=T, check.names=F, row.names=1, comment.char = "")
if(!is.null(nspecies)){
    # 如果给定了前N个物种，则在此处过滤
    nspecies = as.integer(nspecies)
    dt = dt[1:nspecies, ]
}

sample_map = read.table(in_g, sep="\t", header=T, check.names = F, comment.char = "")
x <- zy_format_class_name(dt, sample_map, zy_sample = sid)
rf <- zy_RF_two_class(x$rf_dt, x$rf_map, group=gid, seed=seed, nspecies = nspecies, cross_n = cross)
rf$seed = seed
rf$nspecies = nspecies
if(is.null(nspecies)){
    rf$nspecies = nrow(dt)
}

write.table(rf, out_f, sep="\t", quote=F, row.names=F)
