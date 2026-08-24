get_adjusted_r2 <- function(adonis_object) {
    # n_observations <- ncol(adonis_object$coef.sites) # 用于adonis
    n_observations = tail(adonis_object$Df,1)+1 # 用于adonis2
    d_freedom <- adonis_object$Df[1]
    r2 <- adonis_object$R2[1]
    adjusted_r2 <- RsquareAdj(r2, n_observations, d_freedom)
    adjusted_r2
}
zy_adonis <- function(explanatory_df=NA, response_df=NA, method="bray"){
    # explanatory_df,  列为样本，行为变量
    # response_df, 行为样本，列为变量
    
  intersect(colnames(explanatory_df),row.names(response_df))
  names_ = colnames(response_df)
  nrow_q = nrow(response_df)
  result <- matrix(NA,ncol=4,nrow=length(names_),
                   dimnames = list(names_, c("name","r2","pvalue","adjust.R2")))
  for(c_ in names_){
    ngs = length(response_df[,c_])
    if(ngs == 1 | ngs!=nrow_q){
        next
    }
    if(is.character(response_df[,c_])){
        # 如果是离散型变量，会先转为因子变量
        response_df[,c_] = as.factor(response_df[,c_])
    }
    x = na.omit(response_df[,c_])
    rm_index = attr(x,"na.action")
    message(c_)
    # 针对query， 删除有NA值的样本
    if( !is.null(rm_index)){
      ado = adonis2(t(explanatory_df[,-rm_index])~response_df[-rm_index,c_], method = method)
    }else{
      ado = adonis2(t(explanatory_df)~response_df[,c_], method = method)
    }
    r2 = ado$R2[1]
    p = ado$`Pr(>F)`[1]
    q2 = get_adjusted_r2(ado)
    result[c_,] = c(c_, r2,p, q2)
  }

  result[,2:4] = apply(result[,2:4],2,as.numeric)
  result = as.data.frame(result)
  result
}

zy_parallel_adonis <- function(query=NA, target=NA, method="bray", p=2){
  # 对于target每一列一个样本
  # 对于query，每行一个样本
  library(parallel)
  names_ = colnames(query)
  result <- matrix(NA,ncol=4,nrow=length(names_),
                   dimnames = list(names_, c("name","r2","pvalue","adjust.R2")))
  for(c_ in names_){
    message(c_)
    ngs = length(query[,c_])
    if(ngs == 1 | ngs==nrow_q){
      next
    }
    if(is.character(query[,c_])){
        query[,c_] = as.factor(query[,c_])
    }
    x = na.omit(query[,c_])
    rm_index = attr(x,"na.action")
    # 针对query， 删除有NA值的样本
    if( !is.null(rm_index)){
      ado = adonis2(t(target[,-rm_index])~query[-rm_index,c_], method = method)
    }
    else{
      ado = adonis2(t(target)~query[,c_], method = method)
    }
    r2 = ado$R2[1]
    p = ado$`Pr(>F)`[1]
    q2 = get_adjusted_r2(ado)
    result[c_,] = c(c_, r2,p, q2)
  }
  
  result = as.data.frame(result)
  result[,2:4] = apply(result[,2:4], 2, as.numeric)
  result
}
