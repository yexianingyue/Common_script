get_adjusted_r2 <- function(adonis_object) {
      n_observations <- ncol(adonis_object$coef.sites)
  d_freedom <- adonis_object$aov.tab$Df[1]
    r2 <- adonis_object$aov.tab$R2[1]
    adjusted_r2 <- RsquareAdj(r2, n_observations, d_freedom)
      adjusted_r2
}
zy_adonis <- function(query=NA, target=NA, method="bray"){
  # 都是每一列一个样本
  names_ = colnames(query)
  result <- matrix(NA,ncol=4,nrow=length(names_),
                   dimnames = list(names_, c("name","r2","pvalue","adjust.R2")))
  for(c_ in names_){
    message(c_)
    x = na.omit(query[,c_])
    rm_index = attr(x,"na.action")
    # 针对query， 删除有NA值的样本
    if( !is.null(rm_index)){
      ado = adonis(t(dt[,-rm_index])~query[-rm_index,c_], method = method)
    }
    else{
      ado = adonis(t(dt)~query[,c_], method = method)
    }
    r2 = ado$aov.tab$R2[1]
    p = ado$aov.tab$`Pr(>F)`[1]
    q2 = get_adjusted_r2(ado)
    result[c_,] = c(c_, r2,p, q2)
  }
  
  result = as.data.frame(result)
  result[,2:4] = lapply(result[,2:4],as.numeric)
}

zy_parallel_adonis <- function(query=NA, target=NA, method="bray", p=2){
  # 都是每一列一个样本
  library(parallel)
  names_ = colnames(query)
  result <- matrix(NA,ncol=4,nrow=length(names_),
                   dimnames = list(names_, c("name","r2","pvalue","adjust.R2")))
  for(c_ in names_){
    message(c_)
    x = na.omit(query[,c_])
    rm_index = attr(x,"na.action")
    # 针对query， 删除有NA值的样本
    if( !is.null(rm_index)){
      ado = adonis(t(dt[,-rm_index])~query[-rm_index,c_], method = method)
    }
    else{
      ado = adonis(t(dt)~query[,c_], method = method)
    }
    r2 = ado$aov.tab$R2[1]
    p = ado$aov.tab$`Pr(>F)`[1]
    q2 = get_adjusted_r2(ado)
    result[c_,] = c(c_, r2,p, q2)
  }
  
  result = as.data.frame(result)
  result[,2:4] = lapply(result[,2:4],as.numeric)
}