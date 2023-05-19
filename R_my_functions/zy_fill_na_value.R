library(dplyr)

# 针对表中的数值类型，删除NA值大于cutoff的列，且使用中位数填充NA
zy_fill_na_value <- function(in_matrix=NA, cutoff=1/4, del_na=TRUE, FUN = NA, margin='col',fill_value=FALSE){
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