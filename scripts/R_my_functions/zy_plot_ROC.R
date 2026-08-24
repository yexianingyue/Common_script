library(ggplot2)
library(pROC)
library(dplyr)
library(data.table) # SetDT

############################
#   Version: 20240717
############################
#  change log
#  20240717
#--------
#  group支持向量
############################
my_join <- function(dt, group, join_str="zysplitstr"){
    dt[,group] = lapply(dt[,group],as.character)
    dt$zy_tmp_group = apply(dt[,group], 1, function(x)paste(x, collapse = join_str))
    return(dt)
}

my_split <- function(dt, column, into, sep="zysplitstr"){
    splits <- strsplit(dt[[column]], sep)
    split_dt <- do.call(rbind, splits)
    colnames(split_dt) <- into
    dt[, into] <- split_dt
    return(dt)
}


map_name <- function(roc.list){
    # 返回映射后的新名字
    oc = c() # old name
    nc = c() # new name
    for(rb in names(roc.list)){
        # b = signif(ci(roc.list[[rb]], of="auc")*100, digits=3)
        b = sprintf("%0.1f",ci(roc.list[[rb]], of="auc")*100)
        c = paste(rb, " (",b[2], "%)\t95% CI: " , b[1],"%-",b[3],"%", sep="")
        oc = c(oc,rb)
        nc = c(nc,c)
    }
    names(nc) = oc
    nc
}

calc_auc <- function(dt, pred=NA, true=NA, group=NULL,acc=F,levels=NA,
                     boot_n=2000){
    # group 支持向量
    roc.list = list()
    
    if(typeof(group) == "NULL"){
        if(sum(is.na(levels)) == 1){
            levels = unique(dt[,true])
        }
        roc.list['AUC'] = list( roc(dt[,true], dt[,pred], levels=levels))
        grps = "AUC"
    
    }else{
        ### 如果分组是向量，那就连接起来
        if(length(group) > 1){
            old_group = group
            dt = my_join(dt, group)
            group = "zy_tmp_group"
        }
        grps = unique(dt[,group])
        if(length(grps) == 1){
            if(sum(is.na(levels)) == 1){
                levels = unique(dt[,true])
            }
            roc.list['AUC'] = list(roc(dt[,true], dt[,pred], levels=levels))
        }else{
            for(g in grps){
                temp_dt = dt[dt[,group]==g,]
                if(sum(is.na(levels)) == 1){
                    levels = unique(temp_dt[,true])
                }
                roc.list[as.character(g)] = list(  roc(temp_dt[,true], temp_dt[,pred], levels=levels))
            }
        }
    }
    names_ = names(roc.list)
    result_auc = matrix(NA, ncol=6,nrow=length(grps),
                        dimnames=list(names_, c("low","auc","high","low_acc","acc","high_acc")))
    for(i in names_){
        b = sprintf("%0.4f",ci(roc.list[[i]], of="auc")*100)
        result_auc[i,c(1,2,3)] = as.numeric(b)
        if(isTRUE(acc)){
            ac = ci.coords(roc.list[[i]], x="best", ret="accuracy", transpose=F)
            ac = sprintf("%0.4f",unlist(ac)*100)
            ac[2] = sprintf("%0.4f",coords(roc.list[[i]], x="best", ret="accuracy", transpose=F)*100)
            result_auc[i,c(4,5,6)] = ac
        }
    }
    
    result_auc = as.data.frame(result_auc)
    if(exists("old_group")){
        result_auc$zy_tmp_group = rownames(result_auc)
        result_auc = my_split(result_auc, group, old_group)
        result_auc$zy_tmp_group <- NULL
        rownames(result_auc) = NULL
    } else if( typeof(group) != "NULL" ){
        result_auc[,group] = rownames(result_auc)
        rownames(result_auc) = NULL
    }
    list(table=result_auc)
}

plot_roc <- function(dt, pred=NA, true=NA, group=NULL, levels=NA,
                     fill=FALSE,
                     cols = NA, conf_level=0.95, boot_n=2000){
    # 为了防止曾经修改过小数位等，这边先备份，最后再恢复
    old_scipen = getOption("scipen")
    old_digits = getOption("digits")
    options(scipen=0)
    options(digits=7)
    
    roc.list = list()
    if(typeof(group) == "NULL"){
        if(sum(is.na(cols)) == 1){cols = "darkblue"}
        if(sum(is.na(levels)) == 1){levels = unique(dt[,true])}
        roc.list['AUC'] = list(roc(dt[,true], dt[,pred], levels=levels))
    }else{
        if(length(group) > 1){
            old_group = group
            dt = my_join(dt, group, " - ")
            group = "zy_tmp_group"
        }
        grps = unique(dt[,group])
        if(sum(is.na(cols)) == 1){
            cols=c(1:length(grps))
        }
        for(g in grps){
            if(sum(is.na(levels)) == 1){levels = unique(dt[,true])}
            temp_dt = dt[dt[,group]==g,] %>% droplevels
            roc.list[as.character(g)] = list(  roc(temp_dt[,true], temp_dt[,pred], levels=levels))
        }
    }
    new_name_map <- map_name(roc.list)
    p <- ggroc(roc.list)+
        theme_bw()+
        geom_segment(data = data.frame(x = 0, y = 1),
                     aes(x = x, y = y, xend = 1, yend = 0),
                     color = "#d9d9d9", lwd = .4, inherit.aes = F)+
        scale_color_manual(values=cols, labels=new_name_map)+
        theme(
            panel.grid.minor = element_blank()
            ,panel.grid = element_line(linetype="dashed", color="black", linewidth = 0.2)
            ,panel.border = element_rect(color="black", linewidth = 0.5)
            ,axis.ticks = element_line(color="black", linewidth = 0.5)
            ,axis.ticks.length = unit(2,"mm")
            ,axis.text  = element_text(color="black")
        )
    
    if(isTRUE(fill)){
        ci.list <- lapply(roc.list, function(rocobj)
            setDT(
                data.frame(
                    ci.se(rocobj, specificities=seq(0, 1, 0.1)), check.names=F)
                ,keep.rownames = T)
        )
        data_ci <- bind_rows(ci.list, .id="plot_group")
        data_ci$rn = as.numeric(data_ci$rn)
        p <- p+
            geom_ribbon(data=data_ci,aes(x=rn, ymin=`2.5%`, ymax=`97.5%`, fill=plot_group),
                        alpha=.3,
                        inherit.aes = F)+ # 必须有参数inherit.aes
            scale_fill_manual(values=cols, labels=new_name_map)
    }
    
    # 设置为原来的小数位等
    options(scipen = old_scipen)
    options(digits = old_digits)
    list(plot=p, ROC=roc.list, labels=new_name_map)
}

