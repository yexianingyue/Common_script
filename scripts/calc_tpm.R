#!/usr/bin/Rscript
library(argparse)

parser <- ArgumentParser()
parser$add_argument("-i", help = "matrix with title")
parser$add_argument("-l", help = "contigs' len without title")
parser$add_argument("-o", help = "output")
args <- parser$parse_args()

in_f = args$i
ctg_len = args$l
out_f = args$o

dt = read.table(in_f, sep="\t", header=T, row.names=1, check.names=F)
le = read.table(ctg_len, sep="\t")
rownames(le) = le$V1
le = le[rownames(dt),]
dt = dt[le$V1,]
dt1 = dt/le$V2
dt2 = as.data.frame(t(t(dt1)/colSums(dt1))*100)
write.table(dt2, out_f, quote=F, sep="\t")
