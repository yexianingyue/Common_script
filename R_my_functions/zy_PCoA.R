library(vegan)
library(ggplot2)
library(ggpubr)
library(ggrepel)
library(dplyr)
options(warn=-1)

filter_group <- function(sample_map, group=NA, cut_rate = NA, cut_num=NA){
    cut_off = cut_num
    if(is.finite(cut_rate)){
        if(cut_rate>1 || cut_rate < 0){
            stopifnot("cut_rate should range(0,1)" = 1)
        }else{
            cut_off = sample_map %>%
                dplyr::select(!!sym(group)) %>%
                dplyr::group_by(!!sym(group)) %>%
                dplyr::summarise(count=n()) %>%
                pull(count) %>%
                max() * cut_rate
            cut_off = as.integer(cut_off)
        }
    }
    
    select_grps <- sample_map %>%
        dplyr::select(!!sym(group)) %>%
        dplyr::group_by(!!sym(group)) %>%
        dplyr::summarise(count=n()) %>%
        dplyr::filter(count > cut_off) %>%
        dplyr::pull(!!sym(group))
    message("???????????")
    sample_map %>%
        dplyr::mutate( !!sym(group) := ifelse( !!sym(group) %in% select_grps, !!sym(group), paste("less_",cut_off, sep="")))
}

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

align_dist_sample <- function(dist, sample_map, ID=NA){
    dist = as.matrix(dist)
    intersect_id = intersect(sample_map[,ID], colnames(dist))
    if(length(intersect_id) != nrow(sample_map)){
        message("\033[31m警告\n\tdt和sample_map有数据不匹配\033[0m")
        message("\033[31m\t一共有",length(intersect_id),"个样本可以匹配\033[0m")
        sample_map = sample_map[sample_map[,ID] %in% intersect_id,]
    }
    dist = dist[ sample_map[,ID], sample_map[,ID] ]
    list(dist=as.dist(dist), sample_map=sample_map)
}

zy_pcoa <- function(dt=NA, sample_map=NA, group=NA, ID=NA, sample.color=NULL,
                    ado_method="bray", pca_method="bray",
                    levels=0.95, star_plot=F, ellipse_plot=T,
                    cut_rate = NA, cut_num=NA,
                    title="PCoA", x=1, y=2, ados=T, mydist=NULL){
    
    if(typeof(mydist) != "NULL"){
        fmt_profile = align_dist_sample(mydist, sample_map, ID=ID)
        mydist = fmt_profile$dist
    }else{
        # 对齐profile和分组的样本名称
        fmt_profile = align_dt_sample(dt, sample_map, ID=ID)
        dt = fmt_profile$dt
    }
    sample_map = fmt_profile$sample_map
    
    
    if(is.finite(cut_rate) || is.finite(cut_num)){
        sample_map = filter_group(sample_map, group=group, cut_rate = cut_rate, cut_num=cut_num)
    }
    
    ## colors 
    if ( typeof(sample.color) == "NULL" ){
        sample.color = c(1:length(unique(sample_map[,group])))
    }
    # 统计每个分组各有多少,作为新的图例
    group_summ <- sample_map %>%
        dplyr::select(all_of(group)) %>%
        dplyr::group_by(across({{group}})) %>%
        dplyr::summarise(count=n()) %>%
        dplyr::mutate(new_label=paste(!!sym(group), " (", count, ")", sep=""))
    
    new_label <- structure(group_summ$new_label,names=as.character(unlist(group_summ[,group])))
    
    message(paste(length(unique(sample_map[,group])), "of groups to plot"))
    
    if(typeof(mydist) == "NULL"){
        mydist = vegdist(t(dt), method = pca_method)
    }else{
        mydist = as.dist(mydist)
    }
    
    
    ado_r2 = ado_p = NA
    if (isTRUE(ados)){
        if(length(unique(sample_map[,group])) > 1){
            ## adonis
            ado = adonis2(mydist ~ sample_map[,group])
            ado_r2 = round(ado$R2[1], digits = 4)
            ado_p = ado$`Pr(>F)`[1]
        }
    }
    
    ## PCoA
    k_min = min(10, attr(as.dist(mydist), 'Size')-1)
    pcoa = cmdscale(mydist, k=k_min, eig=T)
    eigs = signif(pcoa$eig/sum(pcoa$eig), 4)*100
    point = pcoa$points
    
    colnames(point) = paste("pcoa.", 1:ncol(point),sep="")
    
    xlab = paste("PCoA", x, " (",eigs[x],"%)", sep="")
    ylab = paste("PCoA", y, " (",eigs[y],"%)", sep="")
    # title = paste(title, "\nR2=",ado_r2,"\npvalue=", ado_p, sep="")
    substitle <- paste0("'R'^2~'='~'", ado_r2, "'~~italic('p')~'='~'", ado_p, "'") %>% 
        as.formula() %>% 
        eval()
    group = ifelse(length(unique(sample_map[,group])) == 1, sample.color[1], group)
    dm = merge(point, sample_map, by.x='row.names', by.y=ID)
    new_names = make.names(group)
    
    illegal_str = length(grep("\\(|\\[|\\{", group))
    
    if( illegal_str != 0 ){
      new_name = make.names(group)
      dm[new_name] = dm[group]
      group = new_name
      message("group has illegal character.")
    }
    p1 <- ggscatter(data=dm, x=paste("pcoa.",x, sep=""),y=paste("pcoa.",y, sep=""),
                    color=group,
                    star.plot = star_plot,
                    ellipse.level = levels,ellipse = ellipse_plot
    )+
        theme_bw()+
        geom_vline(xintercept=0, color="gray", linetype="dashed")+
        geom_hline(yintercept=0, color="gray", linetype="dashed")+
        theme(panel.grid = element_blank(),
              text = element_text(color="black"),
              axis.text = element_text(color="black"),
              axis.ticks = element_line(color="black", linewidth=0.25),
              panel.border = element_rect(colour="black", linewidth=0.25))+
        scale_fill_manual(values=sample.color, guide="none")+
        scale_color_manual(values=sample.color, labels=new_label)+
        labs(x=xlab, y=ylab, title=title, subtitle = substitle)
    list(plot=p1, new_label=new_label)
}

zy_pcoa_se_sd <- function(dt=NA, sample_map=NA, group=NA, ID=NA, sample.color=NULL,
                          ado_method="bray", pca_method="bray",
                          err_bar_type="se",
                          cut_rate = NA, cut_num=NA,
                          err_width=0.01,
                          title="PCoA", x=1, y=2,ados=T, mydist=NULL){
  if(typeof(mydist) != "NULL"){
    fmt_profile = align_dist_sample(mydist, sample_map, ID=ID)
    mydist = fmt_profile$dist
  }else{
    # 对齐profile和分组的样本名称
    fmt_profile = align_dt_sample(dt, sample_map, ID=ID)
    dt = fmt_profile$dt
  }
  sample_map = fmt_profile$sample_map
  
  ## colors 
  if ( typeof(sample.color) == "NULL" ){
    sample.color = c(1:length(unique(sample_map[,group])))
  }
  # 统计每个分组各有多少,作为新的图例
  group_summ <- sample_map %>%
    dplyr::select(all_of(group)) %>%
    dplyr::group_by(across({{group}})) %>%
    dplyr::summarise(count=n()) %>%
    dplyr::mutate(new_label=paste(!!sym(group), " (", count, ")", sep=""))
  
  new_label <- structure(group_summ$new_label,names=as.character(unlist(group_summ[,group])))
  
  message(paste(length(unique(sample_map[,group])), "of groups to plot"))
  
  if(typeof(mydist) == "NULL"){
    mydist = vegdist(t(dt), method = pca_method)
  }else{
    mydist = as.dist(mydist)
  }
  
  ado_r2 = ado_p = NA
  if (isTRUE(ados)){
    if(length(unique(sample_map[,group])) > 1){
      ## adonis
      ado = adonis2(mydist ~ sample_map[,group])
      ado_r2 = round(ado$R2[1], digits = 4)
      ado_p = ado$`Pr(>F)`[1]
    }
  }
  
  ## PCoA
  k_min = min(10, attr(as.dist(mydist), 'Size')-1)
  pcoa = cmdscale(mydist, k=k_min, eig=T)
  eigs = signif(pcoa$eig/sum(pcoa$eig), 4)*100
  point = pcoa$points
  
  colnames(point) = paste("pcoa.", 1:ncol(point),sep="")
  
  xlab = paste("PCoA", x, " (",eigs[x],"%)", sep="")
  ylab = paste("PCoA", y, " (",eigs[y],"%)", sep="")
  
  substitle <- paste0("'R'^2~'='~'", ado_r2, "'~~italic('p')~'='~'", ado_p, "'") %>% 
    as.formula() %>% 
    eval()
  group = ifelse(length(unique(sample_map[,group])) == 1, sample.color[1], group)
  new_names = make.names(group)
  dm = merge(point, sample_map, by.x='row.names', by.y=ID)
  
  point = point[sample_map[,ID], ]
  
  illegal_str = length(grep("\\(|\\[|\\{", group))
  if( illegal_str != 0 ){
    new_name = make.names(group)
    dm[new_name] = dm[group]
    group = new_name
    message("group has illegal character.")
  }
  
  
  tmp_mean = aggregate(point, by=list(c(sample_map[,group])), mean)
  tmp_sd  = aggregate(point, by=list(c(sample_map[,group])), sd)
  tmp_sd  = aggregate(point, by=list(c(sample_map[,group])), sd)
  
  
  plot_data = do.call(data.frame, aggregate(point, by=list(c(sample_map[,group])), 
                                            FUN = function(x){
                                              c(mean = mean(x), sd = sd(x), se = sd(x)/sqrt(length(x)))
                                            }))
  
  plot_x = paste("pcoa.", x, ".mean", sep="")
  plot_y = paste("pcoa.", y, ".mean", sep="")
  
  x_offset = paste("pcoa.", x, ".", err_bar_type, sep="")
  y_offset = paste("pcoa.", y, ".", err_bar_type, sep="")
  
  p1 <- ggplot(data=plot_data, aes(x = .data[[plot_x]], y = .data[[plot_y]], color = Group.1))+
    geom_point(size=10) +
    geom_errorbar(aes( xmin = .data[[plot_x]] - .data[[x_offset]],
                       xmax = .data[[plot_x]] + .data[[x_offset]]),
                  width=err_width
    )+
    geom_errorbar(aes( ymin = .data[[plot_y]] - .data[[y_offset]],
                       ymax = .data[[plot_y]] + .data[[y_offset]]),
                  width=err_width
    )+
    theme_bw()+
    theme(panel.grid = element_blank(),
          text = element_text(color="black"),
          axis.text = element_text(color="black"),
          axis.ticks = element_line(color="black", linewidth=0.25),
          panel.border = element_rect(colour="black", linewidth=0.25))+
    scale_fill_manual(values=sample.color, guide="none")+
    scale_color_manual(values=sample.color, labels=new_label)+
    labs(x=xlab, y=ylab, title=title, subtitle = substitle)
  list(plot=p1, new_label=new_label)
}


zy_pcoa_with_arrow <- function(dt=NA, sample_map=NA, group="Group", ID="Sample", sample.color=NULL,
                               ado_method="bray", pca_method="bray",
                               levels=0.95,x=1, y=2,n_fit=10, mydist=NULL,
                               title="PCoA"){
    
    # 对齐profile和分组的样本名称
    if(typeof(mydist) != "NULL"){
        fmt_profile = align_dist_sample(mydist, sample_map, ID=ID)
        mydist = fmt_profile$dist
    }else{
        # 对齐profile和分组的样本名称
        fmt_profile = align_dt_sample(dt, sample_map, ID=ID)
        dt = fmt_profile$dt
    }
    sample_map = fmt_profile$sample_map
        
    if(typeof(mydist) == "NULL"){
        mydist = vegdist(t(dt), method = pca_method)
    }else{
        mydist = as.dist(mydist)
    }
    
    ## colors 
    if(typeof(sample.color) == "NULL"){
        sample.color = c(1:length(unique(sample_map[,group])))
    }
    if(length(unique(sample_map[,group])) > 1){
        ## adonis
        ado = adonis2(mydist~sample_map[,group])
        ado_r2 = round(ado$R2[1], digits = 4)
        ado_p = ado$`Pr(>F)`[1]
    }else{
        ado_r2 = NA
        ado_p = NA
    }

    
    #-------------------------------------------------
    # pcoa
    # sample.dist=vegdist(t(dt), method=pca_method)
    dt = dt[,colnames(as.matrix(mydist))]
    pca <- cmdscale(mydist, eig=TRUE, k = 10)
    #-----------
    # get species fit
    fit <- envfit(pca, t(dt), permutations = 3, choices=c(x,y))
    fit_val <- vegan::scores(fit, display = c("vectors"))
    fit_val <- fit_val*vegan::ordiArrowMul(fit_val, fill = 2)
    fit_val <- fit_val[head(order(sqrt((fit_val[,1])^2+(fit_val[,2])^2),decreasing = T),n = n_fit),]
    #fit_val <- fit_val[dt %>% arrange(desc(rowMeans((.)))) %>% head(10) %>% rownames(),]
    
    eigs <-round(pca$eig/sum(pca$eig)*100,digits = 2)
    sample_axis <- as.data.frame(pca$points)
    colnames(sample_axis) = paste("pca.", 1:ncol(sample_axis),sep="")
    sample_axis <- sample_axis[sample_map[,ID],]
    sample_axis$Group <- sample_map[,group]
    
    
    xlab = paste("PCA", x, " (",eigs[x],"%)", sep="")
    ylab = paste("PCA", y, " (",eigs[y],"%)", sep="")
    
    subtitle <- paste0("'R'^2~'='~'", ado_r2, "'~~italic('p')~'='~'", ado_p, "'") %>% 
        as.formula() %>% 
        eval()
    
    vector_fd<-function(tab,sam){
        ms<-max(sam[,1]^2,sam[,2]^2)
        mt<-max(tab[,1]^2,tab[,2]^2)
        sqrt(ms)/sqrt(mt)
    }
    Change_axis <- vector_fd(fit_val,sample_axis)*0.5
    
    plot_x = paste("pca.",x, sep="")
    plot_y = paste("pca.",y, sep="")
    micro_x = paste("Dim",x, sep="")
    micro_y = paste("Dim",y, sep="")
    ggplot(sample_axis, aes(x = .data[[plot_x]], y = .data[[plot_y]], color = Group)) +
        stat_ellipse(aes(x = .data[[plot_x]], y = .data[[plot_y]], fill =Group), geom = "polygon", alpha = 0.2, level = levels) +
        geom_point(aes(fill=Group),size = 1, alpha = 0.3, shape=21) +
        scale_color_manual(values = sample.color) +
        scale_fill_manual(values = sample.color) +
        geom_segment(data=data.frame(fit_val), 
                     aes(x=0,y=0,xend=.data[[micro_x]]*Change_axis, yend=.data[[micro_y]]*Change_axis), 
                     arrow=arrow(length=unit(0.2,"cm")), 
                     color='black',alpha=1)  + 
        geom_text_repel(data=data.frame(fit_val), 
                        aes(.data[[micro_x]]*Change_axis, .data[[micro_y]]*Change_axis, label=rownames(fit_val)),
                        color='black',alpha=1)+
        geom_hline(yintercept = 0, color="gray", linetype="dashed")+
        geom_vline(xintercept = 0, color="gray", linetype="dashed")+
        theme_bw()+
        theme(panel.grid = element_blank(),
              text = element_text(color="black"),
              axis.text = element_text(color="black"),
              axis.ticks = element_line(color="black", linewidth=0.25),
              panel.border = element_rect(colour="black", linewidth=0.25))+
        labs(x = xlab,
             y = ylab,
             title = title,
             subtitle=subtitle) 
    
}


zy_dbrda <- function(dt=NA, sample_map=NA, group=NA, ID=NA, sample.color=NULL,
                     ado_method="bray", pca_method="bray",
                     levels=0.95,ellipse_plot=F,star_plot=F,
                     title="dbRDA", x=1, y=2){
    
    # 对齐profile和分组的样本名称
    fmt_profile = align_dt_sample(dt, sample_map, ID=ID)
    dt = fmt_profile$dt
    sample_map = fmt_profile$sample_map
    
    ## colors 
    
    if (typeof(sample.color) == "NULL"){
        sample.color = c(1:length(unique(sample_map[,group])))
    }
    # 统计每个分组各有多少,作为新的图例
    group_summ <- sample_map %>% dplyr::select(all_of(group)) %>% dplyr::group_by(across({{group}})) %>% summarise(count=n()) %>% mutate(new_label=paste(!!sym(group), " (", count, ")", sep=""))
    new_label <- structure(group_summ$new_label,names=unlist(group_summ[,group]))
    
    message(paste(length(sample.color), "of groups to plot"))
    
    otu.dist = vegdist(t(dt), method = pca_method)
    
    if(length(unique(sample_map[,group])) > 1){
        ## adonis
        ado = adonis2(otu.dist ~ sample_map[,group], method = ado_method)
        ado_r2 = round(ado$R2[1], digits = 4)
        ado_p = ado$`Pr(>F)`[1]
        
    }else{
        ado_r2 = NA
        ado_p = NA
    }
    
    ## dbrda
    db_rda = capscale(otu.dist ~ sample_map[,group])
    db_rda_score = scores(db_rda, choices = 1:10)
    point = db_rda_score$sites
    
    eigs = round(summary(eigenvals(db_rda))[2,]*100, digits=4)
    eigs_name = names(eigs)
    
    xlab = paste(eigs_name[x], " (", eigs[x], "% )", sep="")
    ylab = paste(eigs_name[y], " (", eigs[y], "% )", sep="")
    subtitle <- paste0("'R'^2~'='~'", ado_r2, "'~~italic('p')~'='~'", ado_p, "'") %>% 
        as.formula() %>% 
        eval()
    
    dm = merge(point, sample_map, by.x='row.names', by.y=ID)
    p1 <- ggscatter(data=dm, x=eigs_name[x],y=eigs_name[y],
                    color=group,
                    ellipse.level = levels,ellipse = ellipse_plot,
                    star.plot = star_plot
    )+
        theme_bw()+
        geom_vline(xintercept=0, color="gray", linetype="dashed")+
        geom_hline(yintercept=0, color="gray", linetype="dashed")+
        theme(panel.grid = element_blank(),
              text = element_text(color="black"),
              axis.text = element_text(color="black"),
              axis.ticks = element_line(color="black", linewidth=0.25),
              panel.border = element_rect(colour="black", linewidth=0.25))+
        scale_fill_manual(values=sample.color, guide="none")+
        scale_color_manual(values=sample.color, labels=new_label)+
        labs(x=xlab, y=ylab, title=title, subtitle=subtitle)
    list(plot=p1, new_label=new_label)
}
