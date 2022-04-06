zy_pvalue = function(dt=NA, sample_map=NA, group=NA, ID=NA){
    # ID -> ID columns name
    # gorup -> how to group data
    # dt -> profile
    # sample_map -> mapping file
    dt = dt[, sample_map[,ID]]
    grps = unique(sample_map[,group])
    com = t(combn(grps,2))
    nspecies = nrow(dt)
    names = rownames(dt)
    # Avg -> 平均数
    # Avg.weighted.g1 -> 这个分组的加权平均数
    result = matrix(NA,nrow = nrow(com)*nspecies, ncol = 11,
                    dimnames = list(NULL,c("name","g1","g2","Avg.g1","Avg.g2","Avg.weighted.g1","Avg.weighted.g2","all.avg","pvalue","count1","count2")))
    nr = 1
    for (n in 1:nspecies){
        temp_dt = dt[n,]
        for(c in 1:nrow(com)){
            g1 = com[c,1]
            g2 = com[c,2]
            g1s = sample_map[which(sample_map[,group] == g1), ID]
            g2s = sample_map[which(sample_map[,group] == g2), ID]
            dt1 = as.matrix(temp_dt[,g1s])
            dt2 = as.matrix(temp_dt[,g2s])
            c1 = sum(dt1 != 0 )
            c2 = sum(dt2 != 0)
            m1 = mean(dt1)
            m2 = mean(dt2)
            ag1 = sum(dt1)/c1
            ag2 = sum(dt2)/c2
            am = mean(c(dt1,dt2))
            p = wilcox.test(dt1,dt2)$p.value
            result[nr,] = c(names[n], g1, g2, m1, m2, ag1, ag2, am, p, c1, c2)
            #data.frame(name = names[n],g1=g1, g2=g2,mean1 = m1, mean2=m2,pvalue=p, count1=c1, count2= c2)
            nr = nr+1
        }
    }
    result
}
