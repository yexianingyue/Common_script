library(ggplot2)
library(reshape2)
library(vegan)
library(dplyr)
library(RColorBrewer)

norm_data <- function(dt){
    
    prof <- as.data.frame(apply(dt, 2, function(x) {
        col_sum <- sum(x)
        if (col_sum == 0) {
            return(rep(0, length(x)))  # 列和为0时返回全0
        } else {
            return(x / col_sum * 100)  # 否则正常归一化
        }
    }))
    rownames(prof) = rownames(dt)
    prof
}

align_dt_sample <- function(dt, sample_map, ID=NA){
    dt = dt[, colSums(dt, na.rm=T) != 0]
    
    intersect_id = intersect(sample_map[,ID],colnames(dt))
    if(length(intersect_id) != nrow(sample_map)){
        message("\033[31m警告\n\tdt和sample_map有数据不匹配\033[0m")
        message("\033[31m\t一共有",length(intersect_id),"个样本可以匹配\033[0m")
        sample_map = sample_map[sample_map[,ID] %in% intersect_id,]
    }
    dt = dt[,sample_map[,ID]] %>% filter(rowSums(., na.rm=T) !=0)
    list(dt=dt, sample_map=sample_map)
}

zy_compositions <- function(dt=NA, top_N = 10, 
                            title="Composition",taxo.color = NULL,width=0.9,
                            order_func = "order", order_n = 1, label_order=NA,
                            select_label = NULL, colsums = 100, rescale=T, taxo_order=F, themes=NULL){
    # order_n -> 按照第几个丰度排序
    # order_func -> 按照什么对样本排序
    # colsums -> 列和，和参数select_label一起使用，方便从中挑选出来个别的物种进行可视化
    
  ## default  
  if(is.null(themes)){
    themes  = theme_bw() + theme(panel.grid = element_blank(), axis.text.x = element_text(angle=45, hjust=1))
  }
  
    dt = as.data.frame(dt)
    
    ## 归一化
    if (rescale == T){
        dt = norm_data(dt)
    }

    top_N = top_N + 1
    total_color1 = c(brewer.pal(12,"Set3"), brewer.pal(12,"Paired"))
    total_color2 = c("#ed1299","#09f9f5","#246b93","#cc8e12","#d561dd","#c93f00","#ddd53e","#4aef7b","#e86502","#9ed84e","#39ba30","#6ad157","#8249aa","#99db27","#e07233","#ff523f","#ce2523","#f7aa5d","#cebb10","#03827f","#931635","#373bbf","#a1ce4c","#ef3bb6","#d66551","#1a918f","#ff66fc","#2927c4","#7149af","#57e559","#8e3af4","#f9a270","#22547f","#db5e92","#edd05e","#6f25e8","#0dbc21","#280f7a","#6373ed","#5b910f","#7b34c1","#0cf29a","#d80fc1","#dd27ce","#07a301","#167275","#391c82","#2baeb5","#925bea","#63ff4f")
    if(typeof(taxo.color) == "NULL"){
        if(top_N<=24){
            taxo.color = total_color1[1:top_N]
        }else{
            taxo.color = total_color2[1:top_N]
        }
        
    }
    
    if(typeof(select_label) != "NULL"){ # 如果选择了subset，就先选出来
        data = dt[select_label,]
        data['other',] = colsums - colSums(data)
    }else{
        dt = dt[, colSums(dt, na.rm=T) !=0]
        dt = dt[rowSums(dt, na.rm=T)!=0,] # 删除所有样本都没有的物种
        dt = dt[order(rowMeans(dt), decreasing = T),]
        
        dt$taxo_temp = rownames(dt)
        if(nrow(dt) > top_N){dt$taxo_temp[top_N:nrow(dt)] = 'other'} # 如果物种数大于top_N
        data = data.frame(aggregate(. ~ taxo_temp, data=dt, sum), row.names=1, check.names=F)
    }
    data = data[order(rowMeans(data), decreasing=taxo_order),]
    dl = reshape2::melt(as.matrix(data))
    
    # 样本排序方式
    if(order_func %in% c("order","cluster","specific", "all")){
        if (order_func == "order"){
            # 按照含量第order_n个物种对样本进行排序
            label_order = data[order_n,] %>% t() %>% as.data.frame() %>% arrange_all() %>% rownames()
            #label_order = col_names[order(data[order_n,], decreasing=T )]
        }else if(order_func == "cluster"){
            # 按照样本聚类
            otu.dist=vegdist(t(data), method="bray")
            hc = hclust(otu.dist)
            label_order = hc$labels[hc$order]
        }else if(order_func == "specific"){
            label_order = label_order
        }else if(order_func == "all"){
            sample_names = colnames(data)
            label_order =  sample_names[order(colSums(data), decreasing = T)]
            # label_order = data[order(colSums(vlp_dt), decreasing = T)] %>% t() %>% as.data.frame() %>% arrange_all() %>% rownames()
        }
    }
    
    # 分类排序
    tax_ord = rownames(data)
    if(order_n != 1){
        tax_ord = levels(forcats::fct_relevel(tax_ord, tax_ord[order_n]))
    }
    dl$Var1 = factor(dl$Var1, level=rev(tax_ord))
    dl$Var2 = factor(dl$Var2, level=label_order)
    
    p <- ggplot(dl, aes(x=Var2, y=value, fill=Var1))+
        geom_bar(stat='identity',width=width)+
      labs(title = title, y = "Abundance")+
        ggtitle(label=title)+
        themes+
        scale_fill_manual(values=taxo.color)+
        scale_y_continuous(expand = c(0,0))
    
    p
}

zy_group_compositions <- function(dt=NA, sample_map=NA, ID="Sample", group="Group", top_N = 10, 
                                  title="Composition",taxo.color = NULL,width=0.9,label_order=NA,
                                  order_func = "order", order_n = 1,
                                  select_label = NULL, colsums = 100, rescale=T){
    # dt=dt
    # sample_map=samp
    # ID="Sample"
    # group="Group"
    # top_N=10
    # 
    # title="Composition"
    # taxo.color=NULL
    # width=0.9
    # label_order=NA
    # 
    # order_func="order"
    # order_n=1
    # 
    # select_label=NULL
    # colsums=100
    # rescale=T
    
    # order_n -> 按照第几个丰度排序
    # order_func -> 按照什么对样本排序
    
    dt = as.data.frame(dt)
    ## 归一化
    if(rescale == T){
        dt = norm_data(dt)
    }
    
    top_N = min(top_N, nrow(dt))
    if(typeof(sample_map) != "list"){
        cat("\n\033[1;31m[ERROR!!!]\033[0m\t \033[1msample_map\033[0m is not a list or data.frame\n\n")
        return ()
    }
    
    total_color1 = c( "#e31a1c", "#fdbf6f", "#ff7f00", "#cab2d6",
                      "#6a3d9a", "#ffff99", "#b15928","#8dd3c7",
                      "#ffffb3", "#bebada", "#fb8072", "#80b1d3",
                      "#fdb462", "#b3de69", "#fccde5", "#bc80bd",
                      "#ccebc5", "#ffed6f", "#a6cee3", "#1f78b4",
                      "#b2df8a", "#33a02c", "#fb9a99" )
    
    
    total_color2 = c("#ed1299","#09f9f5","#246b93","#cc8e12","#d561dd","#c93f00","#ddd53e","#4aef7b","#e86502","#9ed84e","#39ba30","#6ad157","#8249aa","#99db27","#e07233","#ff523f","#ce2523","#f7aa5d","#cebb10","#03827f","#931635","#373bbf","#a1ce4c","#ef3bb6","#d66551","#1a918f","#ff66fc","#2927c4","#7149af","#57e559","#8e3af4","#f9a270","#22547f","#db5e92","#edd05e","#6f25e8","#0dbc21","#280f7a","#6373ed","#5b910f","#7b34c1","#0cf29a","#d80fc1","#dd27ce","#07a301","#167275","#391c82","#2baeb5","#925bea","#63ff4f")
    if(typeof(taxo.color) == "NULL"){
        if(top_N<=23){
            taxo.color = total_color1[1:top_N]
        }else{
            taxo.color = total_color2[1:top_N]
        }
        
    }
    
    x = align_dt_sample(dt, sample_map, ID=ID)
    dt = x$dt
    sample_map = x$sample_map
    if(typeof(select_label) != "NULL"){ # 如果选择了subset，就先选出来
        dt = dt[select_label,]
        dt['other',] = colsums - colSums(dt)
    }else{
        # dt = dt[, sample_map[,ID] ]
        dt = dt[rowSums(dt, na.rm=T)!=0,] # 删除所有样本都没有的物种
        dt = dt[order(rowMeans(dt), decreasing=T),]
        
        dt$taxo_temp=rownames(dt)
        if(nrow(dt) > top_N){dt$taxo_temp[(top_N+1):nrow(dt)] = 'other'} # 如果物种数大于top_N
        data = data.frame(aggregate(. ~ taxo_temp, data=dt, sum), row.names=1, check.names=F)
    }
    
    
    
    data = data[order(rowMeans(data), decreasing=T),]
    dl = melt(as.matrix(data))
    
    # 样本排序方式
    if(order_func %in% c("order","cluster","specific", "all")){
        if (order_func == "order"){
            # 按照含量第order_n个物种对样本进行排序
            label_order = data[order_n,] %>% t() %>% as.data.frame() %>% arrange_all() %>% rownames()
        }else if(order_func == "cluster"){
            # 按照样本聚类
            otu.dist=vegdist(t(data), method="bray")
            hc = hclust(otu.dist)
            label_order = hc$labels[hc$order]
        }else if(order_func == "specific"){
            label_order = label_order
        }else if(order_func == "all"){
            sample_names = colnames(data)
            label_order =  sample_names[order(colSums(data), decreasing = T)]
            # label_order = data[order(colSums(vlp_dt), decreasing = T)] %>% t() %>% as.data.frame() %>% arrange_all() %>% rownames()
        }
    }
    
    # 分类排序
    tax_ord = rownames(data)
    if(order_n != 1){
        tax_ord = levels(forcats::fct_relevel(tax_ord, tax_ord[order_n]))
    }
    ### 如果fill多了，也不行
    if("other" %in% tax_ord){
        taxo.color = structure(c("#d9d9d9",taxo.color),
        names=c("other",tax_ord[-which(tax_ord== "other")]))
    }
    
    dm = merge(dl, sample_map, by.x='Var2', by.y=ID)
    dm$Var1 = factor(dm$Var1, level=rev(tax_ord))
    dm$Var2 = factor(dm$Var2, level=label_order)
    
    p <- ggplot(dm, aes(x=Var2, y=value, fill=Var1))+
        geom_bar(stat='identity',width=width)+
        theme_bw()+
        theme(panel.grid = element_blank(),
              strip.placement = "outside",
              axis.text.x = element_text(angle=90, hjust=1))+
        # facet_grid(.~get(`group`), scale='free',space = 'free_x'
        facet_grid( paste(". ~ ", group, sep=""), scale='free',space = 'free_x'
                    ,switch = "both" # 标签在下
        )+
        ggtitle(label=title)+
        scale_fill_manual(values=taxo.color)+
        scale_y_continuous(expand = c(0,0))
    
    p
}
