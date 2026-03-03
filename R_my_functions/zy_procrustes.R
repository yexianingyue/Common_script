library(ggplot2)
library(vegan)
library(ade4)

zy_procrustes <- function(x,y, x.lab="X", y.lab="Y", dist.method="bray", title="Procrustes"){
  
  tmp_align <- function(x,y){
    intersect_id = intersect(colnames(x), colnames(y))
    x = x[, intersect_id]
    y = y[, intersect_id]
    
    x = as.data.frame(t(t(x)/colSums(x)))
    y = as.data.frame(t(t(y)/colSums(y)))
    
    return(list(x=x, y=y))
  }
  
  message("align x, y")
  xx = tmp_align(x,y)
  
  message("calc dist")
  x.dist = vegdist(t(xx$x), method = dist.method)
  y.dist = vegdist(t(xx$y), method = dist.method)
  
  message("calc MDS")
  # x.point = as.data.frame(monoMDS(x.dist)$point)
  # y.point = as.data.frame(monoMDS(y.dist)$point)
  
  x.point = as.data.frame(cmdscale(x.dist,eig=T)$point)
  y.point = as.data.frame(cmdscale(y.dist,eig=T)$point)
  
  x.point = x.point[rownames(y.point),]
  
  pro_test = protest(X = x.point, Y = y.point, permutations = 999)
  pval = pro_test$signif
  M2 = signif(pro_test$ss,digits = 3)
  subtitle = paste("M2=", M2,"\np=",pval, sep="")
  procu = procuste(x.point,y.point)
  
  X = as.data.frame(procu$tabX); X$sample = rownames(X)
  Y = as.data.frame(procu$tabY); Y$sample = rownames(Y)
  X$group = x.lab
  Y$group = y.lab
  
  data = rbind(X, Y)
  colnames(data)[1:2] = c("PC1","PC2")
  ggplot(data, aes(x=PC1, y=PC2, shape = group)) + 
    geom_point(size = 3) +
    geom_line(aes(group = sample), alpha=0.5) + 
    #scale_x_continuous(limits=c(-0.3,0.2))+
    #scale_y_continuous(limits=c(-0.15,0.15))+
    theme_bw()+ 
    theme(panel.grid.major = element_blank(),
          panel.grid.minor = element_blank())+
    labs(title=title, subtitle = subtitle)
}
