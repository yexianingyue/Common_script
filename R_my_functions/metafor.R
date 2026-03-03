# Encoding: utf-8
# Author: Jinxin Meng
# Created Data：2022-9-14
# Modified Date: 2022-9-14
# Version: 1.0




# meta.metafor用于小数据的meta分析
# dt作为输入数据，第一列是sample，第二到n为特征列，最后两列是项目内分组和项目间分组, 如下
# sample  feat1  feat2  ..  group proj  
# S1      1.0    4.8    ..  ctr   Mengjx_2021    
# S2      5.2    3.1    ..  ctr   Zhangy_2019
# S3      30.1   16.3   ..  case  Mengjx_2021
# S4      21.4   14.4   ..  case  Zhangy_2019
# ......
# group指定group这列的列名
# group_pair指定group的分组向量
# proj指定proj这列的列名
# measure指定测量效应值选的方法
# method指定计算综合效应案例间方差的方法
# 输出为数据框
# proj  d_Mean  d_Sd  d_N c_Mean  c_Sd  c_N yi  vi  measure model method_tau2 val_tau2  I2  Q Q_pval  feature estimate  ci_lb ci_ub pval
# yi: 效应值
# vi: 案例内方差
# measure: SMD ==> Hedges'g 效应值的计算方法
# val_tau2: 案例间方差的值
# I2: 案例间差异大小占总差异的比例
# Q: # 异质性检验
# Q_pval: # 异质性检验P值 越显著异质性越大
# estimate, ci_lb, ci_ub, pval: 模型的综合评估值μ, 上下限和p值

meta_metafor <- function(dt, group = "group", group_pair = c("Disease", "Control"),
                         proj = "proj", measure = "SMD", method = "REML") {
    library(dplyr)
    library(tibble)
    library(tidyr)
    library(ggplot2)
    library(metafor)
    
    # 表格处理
    dt <- dt %>% 
        rename(proj = all_of(proj), group = all_of(group))
    # feature向量
    feature <- setdiff(colnames(dt), c("sample", "group", "proj"))
    meta_outp <- rbind()
    # 循环每个feature
    x = 1
    nfeature = length(feature)
    for (i in feature) {
        cat("\r", x,"/",nfeature)
        x = x+1
        tib <- dt %>% 
            subset(group%in%group_pair[1]) %>% 
            dplyr::select(all_of(i), proj) %>% 
            rename(index = all_of(i)) %>% 
            group_by(proj) %>% 
            summarise(d_Mean = mean(index), d_Sd = sd(index), d_N = n())
        tib2 <- dt %>% 
            subset(group%in%group_pair[2]) %>% 
            dplyr::select(all_of(i), proj) %>% 
            rename(index = all_of(i)) %>% 
            group_by(proj) %>% 
            summarise(c_Mean = mean(index), c_Sd = sd(index), c_N = n())
        # 合并数据  
        meta_in <- merge(tib, tib2, by= "proj")
        # Calculate effect size and variance in each project. 
        # 计算效应值和案例内方差。
        # We select the method of standardized mean difference provided by Hedges. 
        # 使用Hedges提供的SMD方法计算效应值（yi）和案例内方差（vi)。
        smd_meta <- escalc(measure = measure, data = meta_in, append = T,
                           m1i = d_Mean, m2i = c_Mean, 
                           sd1i = d_Sd, sd2i = c_Sd, 
                           n1i = d_N, n2i = c_N)
        # Calculate cumulative effect size using Random-effect model. 
        # 计算累积效应值，使用随机效应模型，随机效应模型除了随机因素引起的误差外，还考虑一些案例间的差异。
        # We calculate between-case variance using REML method (restricted maximum likelihood estimator) 
        # 使用REML方法计算案例间方差。 
        # tau^2：是案例间方差，认为不同研究之间有一些其他因素导致的差异，总异质性。
        # I^2：去判断案例间差异大小占总差异的指标之一，但是I2不可以作为选择哪种模型（固定vs.随机）的依据。
        # Qt：效应值总体的异质性，是评价效应值的差异程度，表示效应值偏离均值的程度。
        # Qt越大，则效应值越离散，暗示我们有些因素对效应值有强烈的影响，我们可以去寻找一些因素，例如年龄性别，收集数据进行下一步分析。
        # Qt的优势是可以进行显著性检验的。如果p值不显著，那么我们认为案例间的差异是随机因素造成的，这种情况下就不需要往下继续进行Meta分析。
        # estimate 累积效应值，到底是大于0还是小于0，就能知道某种处理下，feature多了还是少了，是否显著，疾病下是否对feature影响明显呢。
        non_na <- smd_meta %>% dplyr::filter(!is.na(yi)) %>% nrow()
        if(non_na !=0 ){
            smd_rma = tryCatch({
                rma(yi, vi, method = method, data = smd_meta)
            }, error = function(e){
                message("默认参数不能收敛，重新设置")
                rma(yi, vi, method = method, data = smd_meta, control=list(stepadj=0.5, maxiter=1000))
            })
            
            
            # merge each data
            smd_meta <- smd_rma$data %>% 
                add_column(measure = measure, # 效应值的计算方法
                           model = "RM",  # 累积效应值计算模型
                           method_tau2 = method, # 随机效应模型估计案例内方差（Tau^2）的计算方法
                           val_tau2 = as.numeric(smd_rma$tau2), # 案例间方差的值
                           I2 = paste0(round(smd_rma$I2, digits = 2), "%"), # 案例间差异大小占总差异的比例
                           Q = smd_rma$QE, # 异质性检验
                           Q_pval = smd_rma$QEp, # 异质性检验P值 越显著异质性越大
                           feature = i,
                           estimate = as.numeric(smd_rma$beta),
                           ci_lb = smd_rma$ci.lb,
                           ci_ub = smd_rma$ci.ub,
                           pval = smd_rma$pval)
            meta_outp <- rbind(meta_outp, smd_meta)
        }else{
            message("\nWarning: ",i," is not suitable.")
        }
    }
    return(meta_outp)
    cat(paste0("== estimate > 0, ==> ", group_pair[1]," ==\n== estimate < 0, ==> ",group_pair[2], " =="))
}

# write.table(x,"meta-analysis.tsv", sep=",")
