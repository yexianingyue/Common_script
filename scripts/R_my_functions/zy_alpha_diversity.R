library(vegan)
library(ggpubr)

align_dt_sample <- function(dt, sample_map, ID=NA){
  intersect_id = intersect(sample_map[,ID],colnames(dt))
  if(length(intersect_id) != nrow(sample_map)){
    message("\033[31m警告\n\tdt和sample_map有数据不匹配\033[0m")
    message("\033[31m\t一共有",length(intersect_id),"个样本可以匹配\033[0m")
    sample_map = sample_map[sample_map[,ID] %in% intersect_id,]
  }
  dt = dt[,sample_map[,ID]] %>% filter(rowSums(.) !=0)
  list(dt=dt, sample_map=sample_map)
}

# 物种累计曲线
get_pan_data=function(dd,permutations){
    dd.curve=specaccum(t(dd), method = "random",permutations=permutations)
    dd.curve.data=data.frame(Sites=dd.curve$sites, Richness=dd.curve$richness, SD=dd.curve$sd)
    #dd.curve.data$label=rep(nm, nrow(dd.curve.data))
    dd.curve.data
}


zy_nspecies = function(dt=NA, sample_map = NA
                       ,group="Group", ID="Sample"
                       ,sample.color=NA
                       ,title="Rarefaction curve analysis"
                       ,permutations=10
                       ){

    ## colors 
    if (missing(sample.color)){
        sample.color = c(1:length(unique(sample_map[,group])))
    }
    message(paste(length(sample.color), "of groups to plot"))

    dt = dt[,sample_map[,ID], drop=F]

    # 循环对每个分组执行函数
    grps = unique(sample_map[,group])
    ngs = length(unique(sample_map[,group]))
    result = rbind()
    ig = 1
    for(g in grps){
      cat("\r", ig," / ", ngs)
      ig = ig + 1
        temp_map = sample_map[which(sample_map[,group]==g),]
        temp_dt = dt[,temp_map[,ID], drop=F]
        temp_result = get_pan_data(temp_dt,permutations)
        temp_result[,group] = g
        result = rbind(result, temp_result)
    }
    
    # 判断是否是因子
    if(is.factor(sample_map[,group])){
        result[,group] = factor(result[,group], levels = levels(sample_map[,group]))
    }
    
    p = ggplot(data=result, aes(x=Sites, y=Richness,color=.data[[group]]))+
        geom_line(size=1)+
        geom_errorbar(aes(ymax=Richness+SD, ymin=Richness-SD), width=.25)+
        theme_bw()+
        theme(panel.grid = element_blank())+
        scale_color_manual(values=sample.color)+
        xlab("Number of samples")+
        ylab("Number of species")+
        ggtitle(title)
    p
}


sigFunc = function(x){
    if(x < 0.001){"***"} 
    else if(x < 0.01){"**"}
    else if(x < 0.05){"*"}
    else{NA}}

numFunc = function(x){
    if(x < 0.001){formatC(x, digits = 1, width = 1, format = "e", flag = "0")}
    else if(x<0.05){formatC(x, digits = 3, width = 1, format = "f", flag = "0")}
    else{NA}
}

zy_alpha = function(dt=NA, sample_map=NA, group="Group", ID="Sample", # 必须参数
                    index="shannon", # 计算参数
                    sample.color=NA, # 美化参数
                    box_width=0.5, # 箱式图宽度
                    title="alpha diversity", # 文字参数,
                    violin = F
                    #, sig = "label" # 显著性是否使用标签代替，如果F，即使不显著也会显示
                    ){
    # pvalue给的是非精确计算exact=F
    ## colors 
    if (any(is.na(sample.color))){
        sample.color = c(1:length(unique(sample_map[,group])))
    }
    message(paste(length(sample.color), "of groups to plot"))

    ## align dt and group
    fmt_profile = align_dt_sample(dt, sample_map, ID=ID)
    sample_map = fmt_profile$sample_map
    dt = fmt_profile$dt
    #dt = dt[,sample_map[,ID]]
    #dt = dt[rowSums(dt)!=0,]

    #alpha
    if(tolower(index) == "obs"){
        alpha = data.frame(alpha=colSums((dt>0)+0))
    }else{
        alpha = data.frame(alpha = vegan::diversity(t(dt),index=index))
    }
    
    dm = merge(alpha,sample_map, by.x='row.names', by.y=ID)
    comp = combn(as.character(unique(dm[,group])),2,list)
    
    p = ggplot(dm, aes(x=.data[[group]], y=alpha,fill=.data[[group]]))
    if(isTRUE(violin)){
        p <- p+
            geom_violin()+
            geom_boxplot(width=box_width, fill="white",
                         position = position_dodge2(preserve = 'single')
                         ,outlier.shape = 21,outlier.fill=NA, outlier.colour = NA)
    }else{
        p <- p+ 
            geom_boxplot(position = position_dodge2(preserve = 'single')
                     ,outlier.shape = 21,outlier.fill=NA, outlier.color="#c1c1c1")
    }
    
    ylabs = structure(c("Number of OTUs","Shannon index", "1 - Simpson index", "Invsimpson index"),
              names=c("obs", "shannon", "simpson","invsimpson"))
    ylab = ylabs[tolower(index)]
    
    
    p <- p+
        theme_bw()+
        theme(panel.grid = element_blank())+
        scale_fill_manual(values=sample.color)+
        geom_signif(comparisons =comp,test='wilcox.test',test.args=list(exact=F),step_increase = 0.1,map_signif_level=numFunc)+
        # geom_signif(comparisons =comp,test='wilcox.test',test.args=list(exact=F),step_increase = 0.1)+
        labs(title=title, y = ylab, x=NULL)

    p
}
