zy_sunplot <- function(dt 
                       ,mylevels=c("phylum","class","order","family","genus","species")
                       ,value=NULL
                       ,plot_label=NULL
){
  library(ggraph)
  library(igraph)
  library(RColorBrewer)
  library(dplyr)
  library(plotly)  
  # mylevels = c("phylum","class","order","family","genus","assessment.species")
  # value = NULL
  # plot_label = NULL
  
  low_level = mylevels[length(mylevels)] ## 取最低分类的列名
  mylevels_num = length(mylevels) # 一共多少个层级
  
  if (is.null(value)){
    value = "value"
    mydt = dt[, c(mylevels)]
    mydt$value = 1
  }else{
    mydt = dt[,c(mylevels,value)]
  }
  
  
  if (is.null(plot_label)){
    plot_label = low_level
    mydt$plot_label = mydt[,plot_label]
  }else{
    mydt[,plot_label] = dt[,plot_label]
  }
  
  ## 为了避免不同层级之间，有相同的名字， 这边现在每列前面加个前缀
  for(i in 1:mylevels_num){
    mydt[[i]] <- paste0("l",i,"__", mydt[[i]])
  }
  
  
  #===============================
  fake_circle<-c()
  
  for (i in 1:nrow(mydt)){
    fake_circle<-append(fake_circle,rep(mydt[[low_level]][i],round(mydt[[value]][i]))) } # 这边需要改
  
  # 按照分类的名字顺序排序
  mydt <- mydt %>%
    arrange(across(all_of(mylevels)))
  
  #---------------------------------------------
  #           构造树状数据
  #---------------------------------------------
  # 构造树状文件
  edges = cbind( rep('origin', length(unique(mydt[,1]))), unique(as.character(mydt[,1])) )
  for(i in 1:(mylevels_num-1)){
    range_ = i:(i+1)
    edges = rbind(edges,as.matrix(mydt[!(duplicated(mydt[c(mylevels[range_])])),range_]))
  }
  edges = data.frame(edges)
  colnames(edges)<-c('from','to')
  vertices0<-data.frame(name=unique(c(as.character(edges$from), as.character(edges$to))))
  
  #---------------------------------------------
  #           构造叶子标签
  #---------------------------------------------
  my_leaf <- mydt[,c(low_level, value, plot_label)] # 这边需要改
  vertices<-left_join(vertices0, my_leaf,by=c("name"=low_level))
  
  #---------------------------------------------
  #           构造颜色数据
  #---------------------------------------------
  ## 颜色就按照最高层及的颜色分类
  my_color = rbind()
  for(i in 1:(mylevels_num)){
    range_ = c(1,i)
    tmp.levels = mylevels[range_]
    my_color = rbind(my_color, as.matrix(mydt[!duplicated(mydt[tmp.levels]), range_]))
  }
  my_color = data.frame(my_color)
  colnames(my_color)<-c('color','name')
  
  vertices<-left_join(vertices, my_color,by='name')
  
  #---------------------------------------------
  #           构造颜色数据
  #---------------------------------------------
  dm = merge(edges,vertices, by.x='to',by.y='name', all.x=T)
  colnames(dm)[1:2] = c("node","parent")
  rownames(dm) = paste(dm$parent,dm$node,sep="")
  
  mm = paste(edges$from, edges$to, sep="")
  dm = dm[mm,]
  
  #---------------------------------------------
  #           不同层级计数
  #---------------------------------------------
  sum_list = lapply(mylevels, function(col){
    sums <- tapply(mydt[[value]], mydt[[col]], sum, na.rm=T)
    data.frame(
      name = names(sums),
      values = as.numeric(sums),
      stringsAsFactors = FALSE
    )
  })
  
  sum_all <- do.call(rbind, sum_list)
  rownames(sum_all) <- NULL
  
  dm1 = merge(dm, sum_all, by.x='node', by.y='name') %>%
    mutate(mylabel = node)
  
  
  dm1$mylabel = gsub("^l\\d__","", dm1$mylabel)
  
  fig <- plot_ly(dm1, values=~values, ids = ~node, labels = ~mylabel, parents = ~parent, type = 'sunburst',  branchvalues = 'total')
  fig
}
