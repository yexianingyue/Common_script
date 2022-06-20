library(ggplot2)
library(pROC)
map_name <- function(roc.list){
  # 返回映射后的新名字
  oc = c() # old name
  nc = c() # new name
  for(rb in names(roc.list)){
    b = signif(ci(roc.list[[rb]], of="auc")*100, digits=3)
    c = paste(rb, " (",b[2],"%)\t95% CI: " , b[1],"%-",b[3],"%", sep="")
    oc = c(oc,rb)
    nc = c(nc,c)
  }
  names(nc) = oc
  nc
}

plot_roc <- function(dt, pred=NA, true=NA, group=NA,
                     cols = NA, conf_level=0.95, boot_n=2000){
  roc.list = list()
  if(is.na(group)){
    if(is.na(cols)){cols = "darkblue"}
    roc.list['AUC'] = list(roc(dt[,true], dt[,pred]))
  }else{
    grps = unique(dt[,group])
    if(is.na(cols)){
      cols=c(1:length(grps))
    }
    for(g in grps){
      temp_dt = dt[dt[,group]==g,]
      roc.list[g] = list(  roc(temp_dt[,true], temp_dt[,pred]))
    }
    
  }
  new_name_map <- map_name(roc.list)
  
  ci.list <- lapply(roc.list, function(rocobj)
    setDT(
      data.frame(
        ci.se(rocobj, specificities=seq(0,1, 0.1)), check.names=F)
      ,keep.rownames = T)
  )
  
  data_ci <- bind_rows(ci.list, .id="plot_group")
  data_ci$rn = as.numeric(data_ci$rn)
  
  p <- ggroc(roc.list)+
    theme_bw()+
    geom_abline(slope=1, intercept=1,
                linetype="dashed",color="gray",alpha=0.7)+
    geom_ribbon(data=data_ci,aes(x=rn, ymin=`2.5%`, ymax=`97.5%`, fill=plot_group),
                alpha=.3,
                inherit.aes = F)+ # 必须有参数inherit.aes
    scale_color_manual(values=cols, labels=new_name_map)+
    scale_fill_manual(values=cols, labels=new_name_map)
  list(plot=p, ROC=roc.list, labels=new_name_map)
}

