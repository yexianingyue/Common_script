get_delta <- function(dt, sample_map, ID="Sample", time="times", times = NULL, individual="person"){
    # 计算差值，需要给定times，计算时，使用后面的时间减去前面的
    message(paste(times[2], " - ", times[1], sep=""))

    sample_map = sample_map[sample_map[,time] %in% times, ]

    individuals <- data.frame(table(sample_map[,individual]))
    raw_individuals = nrow(individuals)

    individuals <- subset(individuals, Freq == 2)
    filtered_individuals = nrow(individuals)

    if(filtered_individuals != raw_individuals ){
        message("发现不成对的样本")
    }


    intersect_id <- intersect(colnames(dt), sample_map[,ID])
    if(length(intersect_id) != nrow(sample_map)){
        message("\033[1m", nrow(sample_map) - length(intersect_id),"\033[0m Samples were not matched.")
    }
    if(typeof(times) == "NULL" | length(times) != 2){
        stop("需要指定groups")
    }

    sampf <- sample_map[sample_map[,ID] %in% intersect_id, ]
    dtf <- dt[, intersect_id]

    sampf1 <- sample_map[ sample_map[,time] == times[1], ]
    dtf1 = dt[,sampf1[,ID]]
    colnames(dtf1) = sampf1[,individual]

    sampf2 <- sample_map[ sample_map[,time] == times[2], ]
    dtf2 = dt[,sampf2[,ID]]
    colnames(dtf2) = sampf2[,individual]

    dtf2 = dtf2[, colnames(dtf1)]

    delt_dt = dtf2 - dtf1
    return(delt_dt)
}


# 针对表中的数值类型，删除NA值大于cutoff的列，且使用中位数填充NA
zy_fill_na_value <- function(in_matrix=NA, cutoff=1/4, del_na=TRUE, FUN = NA, margin='col',fill_value=FALSE){
    # FUN   -> 记得不要忘了写如何处理NA，否则最后的结果可能和原来的一样
    # del_na  -> 对于不满足的行/列是否要删除
    # cutoff -> 最多有多少比例的NA值
    # 只处理数值类型
    if(margin=='col'){
        del_count = 0
        total_num = nrow(in_matrix)
        for(i in 1:ncol(in_matrix)){
            na_num = sum(is.na(in_matrix[,i]))
            if(is.function(FUN)){
                fill_value = FUN(as.matrix(in_matrix[i,]))
            }else{
                fill_value
            }
            if (na_num/total_num < cutoff){
                in_matrix[,i][is.na(in_matrix[,i])] = fill_value
            }else{
                del_count = del_count + 1
            }
        }
        # 储存将要删除的列
        if (isTRUE(del_na)){
            del_c = c()
            for(i in 1:ncol(in_matrix)){
                if(!is.character(in_matrix[,i])){
                    if(is.na(sum(in_matrix[,i]))){
                        del_c = c(del_c, i)
                    }
                }
            }
            message("delete ",del_count," items")
            if(is.null(del_c)){# 如果将要删除的列为空，直接返回就行
                return(as.data.frame(in_matrix, check.names=F))
            }
            return(as.data.frame(in_matrix[,-del_c], check.names=F))
        }else{
            return(as.data.frame(in_matrix, check.names=F))
        }
    }else{
        del_count = 0
        total_num = ncol(in_matrix)
        for(i in 1:nrow(in_matrix)){
            na_num = sum(is.na(in_matrix[i,]))
            if(is.function(FUN)){
                fill_value = FUN(as.matrix(in_matrix[i,]))
            }else{
                fill_value
            }
            if (na_num/total_num < cutoff){
                in_matrix[i,][is.na(in_matrix[i,])] = fill_value
            }else{
                del_count = del_count + 1
            }
        }
        # 储存将要删除的行
        if (isTRUE(del_na)){
            del_c = c()
            for(i in 1:nrow(in_matrix)){
                if(!is.character(in_matrix[i,])){
                    if(is.na(sum(in_matrix[i,]))){
                        del_c = c(del_c, i)
                    }
                }
            }
            message("delete ",del_count," items")
            if(is.null(del_c)){# 如果将要删除的列为空，直接返回就行
                return(as.data.frame(in_matrix, check.names=F))
            }
            return(as.data.frame(in_matrix[-del_c,], check.names=F))
        }else{
            return(as.data.frame(in_matrix, check.names=F))
        }
    }
}

