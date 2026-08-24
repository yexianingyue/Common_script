library(dplyr)
zy_pvalue_one_vs_others = function(dt=NA, sample_map=NA, group="Group", ID="Sample",p.method="wilcox.test"){
    grps = unique(sample_map[,group])
    result = rbind()
    for(g in grps){
        sample_map = sample_map %>% mutate(zy_temp_group=ifelse(get(`group`)==g,get(`group`),"other"))
        temp_result = zy_pvalue(dt, sample_map, group="zy_temp_group", ID=ID, p.method=p.method)
        temp_result$qvalue = p.adjust(temp_result$pvalue, method = "BH")
        result = rbind(result,temp_result)
    }
    
    return(result)
}

my_siglabs <- function(dt, name='name', lab1='g1', lab2='g2'){
    # 如果多分组比较时，觉得线条太麻烦了，这个可以生成标签，生成分组A显著的其余分组名字
    # dt就是筛选出来的显著的
    features = unique(dt[,name])
    res = rbind()
    for( feature in features){
        dtf = dt[dt[,name] == feature, ]
        labs = unique(unlist(dtf[,c(lab1, lab2)]))
        for(lab in labs){
            sig_labs = unique(unlist(dtf[dtf[,lab1]== lab | dtf[,lab2]==lab, c(lab1, lab2)]))
            tolabs = paste(setdiff(sig_labs, lab), collapse=",")
            tmp <- data.frame(name=feature, from=lab, to=tolabs)
            res = rbind(res, tmp)
        }
    }
    res
}


zy_pvalue = function(dt=NA, sample_map=NA, group="Group", ID="Sample", p.method="wilcox.test"){
    # 如果有多个分组，all.avg只代表当前两个分组的均值，min_avg, min_fd...也一样
    # ID -> ID columns name
    # gorup -> how to group data
    # dt -> profile
    # sample_map -> mapping file
    
    
    test.arg = c(wilcox.test, t.test)
    names(test.arg) = c("wilcox.test", "t.test")
    my_test = test.arg[[p.method]]
    intersect_id = intersect(sample_map[,ID],colnames(dt))
    
    if(length(intersect_id) != nrow(sample_map)){
        message("\033[31m警告\n\tdt和sample_map有数据不匹配\033[0m")
        message("\033[31m\t一共有",length(intersect_id),"个样本可以匹配\033[0m")
        sample_map = sample_map[sample_map[,ID] %in% intersect_id,]
    }else{
        message("\033[31mInfo\t数据和分组完全匹配\033[0m")
    }
    dt = dt[, sample_map[,ID]]
    
    raw_ncol = ncol(dt)
    raw_nrow = nrow(dt)
    dt = dt[rowSums(dt)!=0,]
    # dt = dt[, colSums(dt)!=0]这一步不应该有
    f_ncol = ncol(dt)
    f_nrow = nrow(dt)
    
    if(f_ncol != raw_ncol || raw_nrow != f_nrow){
        message(paste("delete all items is 0 -> columns:", raw_ncol - f_ncol, " rows:" ,raw_nrow - f_nrow, sep=""))
    }
    
    grps = unique(sample_map[,group])
    com = t(combn(grps,2))
    nspecies = nrow(dt)
    names_ = rownames(dt)
    # Avg -> 平均数
    # Avg.weighted.g1 -> 这个分组的加权平均数
    result = data.frame(matrix(NA,nrow = nrow(com)*nspecies, ncol = 19,
                               dimnames = list(NULL,c("name","g1","g2","Avg.g1","Avg.g2","fold_change","enriched",
                                                      "all.avg","all.var","pvalue",
                                                      "count1","count2","total_count1","total_count2",
                                                      "rank1.avg", "rank2.avg","method","var1","var2"))))
    nr = 1
    for (n in 1:nspecies){
        cat("\r",n, " / ", nspecies)
        temp_dt = dt[n,]
        for(c in 1:nrow(com)){
            g1 = com[c,1]
            g2 = com[c,2]
            
            g1s = sample_map[which(sample_map[,group] == g1), ID] # group
            g2s = sample_map[which(sample_map[,group] == g2), ID]
            
            dt1 = as.matrix(temp_dt[,g1s]) # data
            dt2 = as.matrix(temp_dt[,g2s])
            
            c1 = sum(dt1 != 0, na.rm=T)  # count !0
            c2 = sum(dt2 != 0, na.rm=T)
            
            tc1 = length(dt1) # total count
            tc2 = length(dt2)
            
            m1 = mean(dt1, na.rm=T) # mean data
            m2 = mean(dt2, na.rm=T)
            
            var_1 = var(as.numeric(dt1), na.rm=T) # var data
            var_2 = var(as.numeric(dt2), na.rm=T)
            
            am = mean(c(dt1,dt2), na.rm=T) # total mean
            a_var=var(c(dt1,dt2), na.rm=T) # total var
            p = my_test(dt1,dt2)$p.value # pvalue
            fold_change = ifelse(m1>m2, m1/m2, m2/m1) # fold change
            enriched = ifelse(m1>m2, g1,g2) # enriched
            
            m = sample_map[which(sample_map[,group] %in% c(g1,g2)), ID]
            all_rank = rank(temp_dt[,m])
            
            rank1 = all_rank[colnames(dt1)] # rank
            rank2 = all_rank[colnames(dt2)]
            
            rank1.avg = mean(rank1) # mean rank
            rank2.avg = mean(rank2)
            
            result[nr,] = c(names_[n], g1, g2, m1, m2, 
                            fold_change, enriched, am, a_var,
                            p, c1, c2, tc1, tc2,rank1.avg, rank2.avg,
                            method=p.method, var1=var_1, var2=var_2)
            nr = nr+1
        }
    }
    result[,c(4:6,8:16,18,19)] = lapply(result[,c(4:6,8:16,18,19)], as.numeric)
    result
}

zy_qvalue = function(dt=NA, sample_map=NULL, pvalue_dt=NULL, group="Group", ID="Sample",p.method="wilcox.test",
                     adj.method="BH", min_count=0, min_prevalence=0, min_avg=0,min_fd=0){
    # pvalue_dt是zy_pvalue出来的原始结果
    # 如果有多个分组，all.avg只代表当前两个分组的均值，min_avg, min_fd...也一样
    # min_count 至少有一个分组有这么多样本
    # min_prevalence 至少有一个分组大于这么多的样本有
    # avg 总体的平均含量阈值
    # fd fold-change阈值
    
    if(min_prevalence < 0 || min_prevalence > 1){
        stop("min_prevalence should be in 0~1")
    }
    result = rbind()
    if (typeof(pvalue_dt) != "NULL" && typeof(sample_map) != "NULL"){
        result.pval = pvalue_dt
    }else{
        result.pval <- as.data.frame(zy_pvalue(dt, sample_map, group=group, ID=ID, p.method=p.method))
    }
    comp <- combn(unique(sample_map[,group]),2,list)
    for ( i in 1:length(comp)){
        # 筛选出要计算qvalue的数据
        result.tmp1 <- result.pval %>%
            dplyr::filter(g1 == comp[[i]][1] & g2 == comp[[i]][2])
        
        result.tmp1$qvalue = NA
        
        result1 <- result.tmp1 %>%
            dplyr::filter((count1 >= min_count | count2 >= min_count)
                          & (count1/total_count1 > min_prevalence | count2/total_count2 > min_prevalence)
                          & fold_change >= min_fd & all.avg >= min_avg)
        
        result1$qvalue = p.adjust(result1$pvalue, method=adj.method)
        
        result2 <- result.tmp1 %>%
            dplyr::filter((count1 < min_count & count2 < min_count)
                          & (count1/total_count1 < min_prevalence & count2/total_count2 < min_prevalence)
                          | fold_change < min_fd | all.avg < min_avg) %>%
            rbind(result1)
        result = rbind(result,result2)
    }
    result
}
