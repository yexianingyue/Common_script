library(vegan)
library(ggpubr)


zy_alpha = function(dt=NA, sample_map=NA, group="Group", ID="Sample", # 必须参数
                    index="shannon", # 计算参数
                    sample.color=NA, # 美化参数
                    title="alpha diversity" # 文字参数
){
  # pvalue给的是非精确计算exact=F
  ## colors 
  if (is.na(sample.color) || is.nan(sample.color)){
    sample.color = c(1:length(unique(sample_map[,group])))
  }
  message(paste(length(sample.color), "of groups to plot"))
  
  ## align dt and group
  dt = dt[,sample_map[,ID]]
  dt = dt[rowSums(dt)!=0,]
  
  #alpha
  alpha = data.frame(alpha = diversity(t(dt),index=index))
  dm = merge(alpha,sample_map, by.x='row.names', by.y=ID)
  comp = combn(unique(dm[,group]),2,list)
  
  p = ggplot(dm, aes(x=.data[[group]], y=alpha,fill=.data[[group]]))+
    geom_boxplot(position = position_dodge2(preserve = 'single'),
                 outlier.shape = 21,outlier.fill=NA, outlier.color="#c1c1c1")+
    theme_bw()+
    theme(panel.grid = element_blank())+
    scale_fill_manual(values=sample.color)+
    #geom_signif(comparisons =comp,test='wilcox.test',test.args=list(exact=F),step_increase = 0.1,map_signif_level=sigFunc)+
    geom_signif(comparisons =comp,test='wilcox.test',test.args=list(exact=F),step_increase = 0.1)+
    ggtitle(title)
  
  p
}