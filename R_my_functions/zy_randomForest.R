library(randomForest)
library(tidyselect)
library(dplyr)


zy_Leave_One_Out_RandomFroestClassification <- function(rf_map=NA, rf_dt=NA,
                                          sample=NA, group=NA,
                                          nspecies=NA,seed=123,
                                          ntree=999){
  # 是否给定物种数量
  if(! is.na(nspecies)){
    rf_dt = rf_dt[1:nspecies,] %>% filter(rowSums(rf_dt) !=0)
  }
  set.seed(seed)
  # 用于二分类
    rf_map[,group] = as.factor(rf_map[,group])
    # rf_map$zy_temp_Group = ifelse(rf_map[,group] == Control,"Control","Disease")
    temp_result = list()
    x = randomForest(x= t(rf_dt), y = rf_map[,group], ntree=ntree,importance=TRUE, proximity=TRUE)
    for(i in 1:ncol(rf_dt)){
        message("sample: ", i)
        test_sample = rf_map[i,]
        test_dt = rf_dt[,test_sample[,sample]]
        train_sample = rf_map[-i,]
        train_dt = rf_dt[,train_sample[,sample]]
        message("train")
        #fit = randomForest(train_sample[,group]~.,data=t(train_dt), ntree=ntree,importance=TRUE, proximity=TRUE)
        fit = randomForest(x= t(train_dt), y = train_sample[,group], ntree=ntree,importance=TRUE, proximity=TRUE)
        message("test\n")
        pred = as.data.frame(predict(fit, t(test_dt), type='prob'))
        pred[,sample] = test_sample[,sample]
        pred[,group] = test_sample[,group]
        temp_result = append(temp_result, list(pred))
    }
    temp_result <- do.call("rbind", temp_result)
    list(pred=temp_result, imporv = x$importance)
}





zy_RF_two_class <- function(rf_dt=NA, rf_map=NA, 
                            sample=NA, group=NA, 
                            ntree=999, cross_n = 10,
                            nspecies = NA,
                            seed=123){
  # 返回每个样本的预测值
  #
  # 是否给定物种数量
  if(! is.na(nspecies)){
    rf_dt = rf_dt[1:nspecies,] %>% filter(rowSums(.) !=0)
  }
  set.seed(seed)
  gs = rf_map %>%
    group_by(get(group)) %>%
    summarise(value=n()) %>%
    as.data.frame()
  
  g1 <- rf_map %>%
    filter(get(group)==gs[1,1]) %>%
    mutate(rf_temp_cross_n=rep(sample(1:cross_n), gs[1,2]/cross_n+1)[1:gs[1,2]])
  
  g2 <- rf_map %>%
    filter(get(group)==gs[2,1]) %>%
    mutate(rf_temp_cross_n = rep(sample(1:cross_n), gs[2,2]/cross_n+1)[1:gs[2,2]])
  
  rf_map = rbind(g1,g2)
  rf_map$Group = as.factor(rf_map$Group)
  
  predict_result = list() # 储存预测的结果

  for(i in 1:cross_n){
    test_sample = rf_map[rf_map$rf_temp_cross_n == i,]
    test_dt = rf_dt[,test_sample[,sample]]
    
    train_sample = rf_map[rf_map$rf_temp_cross_n != i,]
    train_dt = rf_dt[,train_sample[,sample]]
    fit = randomForest(train_sample[,group]~.,data=t(train_dt), ntree=ntree,importance=TRUE, proximity=TRUE)
    pred = as.data.frame(predict(fit, t(test_dt), type='prob'))
    predict_result = append(predict_result, list(pred)) # 储存每个样本预测到的结果
  }
  predict_result <- do.call("rbind", predict_result)
  predict_result = merge(predict_result, rf_map[,c(sample,group)], by.x="row.names", by.y=sample)
  predict_result
}