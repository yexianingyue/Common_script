library(ade4)
library(cluster) # pam hcut
library(clusterSim)
library(factoextra) # fviz_nbclust
library(dplyr)
library(tidyselect)

message("对于肠型分析，
        data.dist = get_dist_JSD(dt)
        get_plot_CH_index(dt, data.dist) # 根据这个选择最好的分类个数
        get_sample_enterotype(data.dist, ncluster)")
## 写函数

# 获得每个类别中，平均丰度最高的物种名称
get_sample_enterotype <- function(data.dist, dt, ncluster){
    k = ncluster
    data.cluster_temp = get_pam_cluster(data.dist, k)
    enterotype_map = data.frame(Sample=names(data.dist),enterotype=as.factor(data.cluster_temp))
    types = rep(NA,k)
    for(i in 1:k){
        empf = enterotype_map %>% filter(enterotype==i)
        taxo = dt[,empf$Sample] %>% 
            filter(rowSums(.)!=0) %>%
            summarise(variable=rownames(.),rowmean = rowMeans(.)) %>%
            arrange(desc(rowmean)) %>%
            head(1)
        names(types)[i] = i
        types[i] = taxo$variable
    }
    types = as.data.frame(types)
    merge(enterotype_map, types,by.x="enterotype", by.y='row.names')
}

## JSD计算样品距离
get_dist_JSD <- function(inMatrix, pseudocount=NA, ...){
    # inMatrix列和应当为1，否则
    # pseudocount 如果为NA，则取用最小值/1000
    ## 函数：JSD计算样品距离
    matrix_sum = sum(inMatrix[,1])
    if(matrix_sum != 1){
        message("inMatrix colsums != 1, I will renormalization.")
        inMatrix = inMatrix / matrix_sum
    }
    if(is.na(pseudocount)){
        pseudocount = min(dt[dt!=0]) / 10
    }
    
    KLD <- function(x,y) sum(x *log(x/y))
    JSD <- function(x,y) sqrt(0.5 * KLD(x, (x+y)/2) + 0.5 * KLD(y, (x+y)/2))
    
    matrixColSize <- ncol(inMatrix)
    matrixRowSize <- nrow(inMatrix)
    colnames <- colnames(inMatrix)
    resultsMatrix <- matrix(0, matrixColSize, matrixColSize)
    
    # inMatrix = apply(inMatrix, 1:2, function(x) ifelse (x==0, pseudocount, x))
    inMatrix[inMatrix == 0] = pseudocount
    
    for(i in 1:matrixColSize){
        cat("\r", i,"/",matrixColSize)
        di <- as.vector(inMatrix[, i])
        for(j in i:matrixColSize)
        {
            if (j == i){
                resultsMatrix[i, j] = 0
            }else{
                tmp_dist = JSD(di, as.vector(inMatrix[, j]))
                resultsMatrix[i, j] = tmp_dist
                resultsMatrix[j, i] = tmp_dist
            }
        }
    }
    
    colnames -> colnames(resultsMatrix) -> rownames(resultsMatrix)
    as.dist(resultsMatrix) -> resultsMatrix
    # 两两重复矩阵去重，as.dist
    attr(resultsMatrix, "method") <- "dist"
    return(resultsMatrix)
}

get_pam_cluster = function(x, ncluster){
    ## 函数：PAM聚类样品
    # x is a distance matrix and k the number of clusters
    k = ncluster
    require(cluster)
    cluster = as.vector(pam(as.dist(x), k, diss=TRUE)$clustering)
    return(cluster)
}

get_CH_index <- function(data, data.dist, ncluster){
    # data：行 -> 物种， 列 -> 样本
    k = ncluster
    if(k == 1){return(NA)}
    data.cluster_temp = get_pam_cluster(data.dist, k)
    index.G1(t(data), data.cluster_temp,  d = data.dist, centrotypes = "medoids")
}

get_plot_CH_index <- function(data, data.dist, ncluster=20){
    nclusters = rep(NA,ncluster)
    for(k in 1:ncluster){
        nclusters[k] = get_CH_index(data,data.dist,k)
    }
    plot(nclusters, type="h", xlab="k clusters", ylab="CH index", main="Optimal number of clusters") # 查看K与CH值得关系
    ch.plot = recordPlot()
    return(list(data=nclusters, plot=ch.plot))
}

get_other_index <- function(x, FUNcluster=pam, method="silhouette", nclusters=10){
    fc.data = fviz_nbclust(t(x),FUNcluster, method = method, k.max=nclusters)
    plot(fc.data)
    fc.plot = recordPlot()
    return(fc.data)
}


# read data
# dt = read.table("metaphlan_genus.profile", sep="\t", header=T, row.names=1, check.names=F)

# calc jsd, run it only once
# data.dist = get_dist_JSD(dt,pseudocount=0.00000001)
# save(data.dist, file="./jsd.Rdata")

# other cluster type
# message("pam")
# fc.pam <- fviz_nbclust(t(dt),pam, method = "silhouette")
# message("hclu")
# fc.hclu <- fviz_nbclust(t(dt),hcut, method = "silhouette")
# plot(fc.pam)
# plot(fc.hclu)


## CH index
# nclusters = rep(NA,20)

# plot(nclusters, type="h", xlab="k clusters", ylab="CH index", main="Optimal number of clusters") # 查看K与CH值得关系


