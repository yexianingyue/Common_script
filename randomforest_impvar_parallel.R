#!/usr/bin/Rscript

library(argparse, quietly = T)

get_args <- function(){
    parser <- ArgumentParser()
    parser$add_argument("-i", default=NULL,help = "profile")
    parser$add_argument("-g", help = "group file")
    parser$add_argument("-o", help = "output file")
    parser$add_argument("-sid", metavar="sample ID", default="Sample", help = "the sample id in group file (default: Sample).")
    parser$add_argument("-gid", metavar="group ID", default="Group", help = "the group id in group file (default: Group)")
    parser$add_argument("-sorted", default=NULL, help = "output sorted profile")
    parser
}

parser = get_args()
args = parser$parse_args()
if(is.null(args$i)){
    parser$print_help()
    quit("no", status=127)
}


# 必要参数
in_f = args$i
in_g = args$g
out_f = args$o

# 配置参数
sid = args$sid
gid = args$gid

# 可选参数
out_sorted = args$sorted

# 常数
threads = 10

library(parallel, quietly = T)
source("/share/data1/zhangy2/scripts/R_my_functions/zy_randomForest.R")
zy_parallel <- function(y){
    library(randomForest, quietly = T) # 这边导入时，不会打印信息
    randomForest(x$rf_map$Group~., data=t(x$rf_dt),ntree=999,importance=TRUE, proximity=TRUE)$importance[,2]
}

# read file
######################
message("\n\n# read profile: ", in_f)
dt = read.table(in_f, check.names=F, row.names=1, header=T, comment.char = "")
message("----------\nprofile: ", ncol(dt), "  columns\t", nrow(dt), "  features.", "\n\n")

message("# read group file: ", in_g)
sample_map = read.table(in_g,header=T, check.names=F, sep="\t", comment.char = "")
message("----------\ngroup file: ", nrow(sample_map), "\n\n")

# ***** 格式化名字，如果有特殊字符，随机森岭会报错
x <- zy_format_class_name(dt, sample_map, zy_sample=sid)
message("# RandomForest status:\n----------\nNumber of samples: ", ncol(x$rf_dt), "\nNumber of features: ", nrow(x$rf_dt))
######################




# ***** 分类分组一定得是因子
x$rf_map[,gid] = as.factor(x$rf_map[,gid])

cl <- makeCluster(threads, type="FORK") # PSOCK 适用于所有系统，FORK只用于unix/max, 用于共享内存
clusterExport(cl,c("x"))  # 导入共享数据
# clusterEvalQ(cl, library(randomForest)) # 导入共享包，但是会返回每个节点的包名列表

rfs <- parLapply(cl, 1:10, zy_parallel)
stopCluster(cl)
species_name_map = data.frame(raw=rownames(dt), formet = make.names(rownames(dt)))

impvar_result = do.call("cbind",rfs) # 合并

# 替换名字
result = merge(species_name_map,impvar_result,by.x='raw', by.y='row.names')
rownames(result) = result$raw
result = result[, c(-1,-2)]
result = result[order(rowMeans(result), decreasing = T),]

write.table(result, out_f, sep="\t", quote=F)
if(!is.null(out_sorted)){
    if(out_sorted == in_f){
        message("Error: ",out_sorted, "==", in_f)
        quit("no", status=127)
    }
    dt = dt[rownames(result), ]
    write.table(dt, out_sorted, sep="\t", quote = F)
}
