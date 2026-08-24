library(glmnet, quietly = T, warn.conflicts=T)
library(tidyselect, quietly = T)
library(dplyr, quietly = T)


zy_Leave_One_Out_lasso <- function(rf_dt=NA, rf_map=NA,
                                   zy_sample="zy_RF_temp_ID", group=NA,
                                                        nspecies=NA,seed=123,
                                                        ntree=999){
  
  # 是否给定物种数量
  if(! is.na(nspecies)){
    rf_dt = rf_dt[1:nspecies,] %>% dplyr::filter(rowSums(.) !=0)
  }
  set.seed(seed)
  # 用于二分类
  rf_map[,group] = as.factor(rf_map[,group])
  rf_dt = rf_dt[,rf_map[,zy_sample]]
  # rf_map$zy_temp_Group = ifelse(rf_map[,group] == Control,"Control","Disease")
  temp_result = list()
  x = randomForest(x= t(rf_dt), y = rf_map[,group], ntree=ntree,importance=TRUE, proximity=TRUE)
  ns = ncol(rf_dt)
  for(i in 1:ns){
    cat("\rsample: ", i, " / ", ns)
    test_sample = rf_map[i,]
    test_dt = rf_dt[,test_sample[,zy_sample]]
    train_sample = rf_map[-i,]
    train_dt = rf_dt[,train_sample[,zy_sample]]
    cat("\rsample: ", i, " / ", ns, " -> train")
    #fit = randomForest(train_sample[,group]~.,data=t(train_dt), ntree=ntree,importance=TRUE, proximity=TRUE)
    fit = randomForest(x= t(train_dt), y = train_sample[,group], ntree=ntree,importance=TRUE, proximity=TRUE)
    cat("\rsample: ", i, " / ", ns, " -> test")
    pred = as.data.frame(predict(fit, t(test_dt), type='prob'))
    pred[,zy_sample] = test_sample[,zy_sample]
    pred[,group] = test_sample[,group]
    temp_result = append(temp_result, list(pred))
  }
  temp_result <- do.call("rbind", temp_result)
  # list(pred=temp_result, imporv = x$importance)
  list(pred=temp_result, imporv = importance(x))
}


zy_format_class_name <- function(rf_dt=NA, rf_map=NA, zy_sample=NA){
  row.names(rf_dt) = make.names(row.names(rf_dt))
  colnames(rf_dt) = make.names(colnames(rf_dt))
  
  rf_map$zy_RF_temp_ID = make.names(rf_map[,zy_sample])
  rf_map[,zy_sample] = make.names(rf_map[,zy_sample])
  
  ndt = ncol(rf_dt)
  nmap = nrow(rf_map)
  
  intersect_id = intersect(rf_map$zy_RF_temp_ID, colnames(rf_dt))
  if(nmap != ndt){
    message("rf_dt -> nsample: ",ndt)
    message("rf_map -> nsample: ",nmap)
    message("intersect -> ", length(intersect_id))
  }
  rf_dt = rf_dt[,intersect_id]
  rf_map = rf_map[match(intersect_id, rf_map[,zy_sample]),]
  return(list(rf_dt=rf_dt, rf_map=rf_map))
}

zy_lasso <- function(train_dt=NA, train_map=NA, test_dt=NA, test_map=NA, 
                  ntree=999,seed=123,discrete=T,
                  zy_sample="zy_RF_temp_ID", group=NA,
                  test_sample=NA, test_group=NA,
                  train_sample=NA, train_group=NA){
  if(!is.na(zy_sample)){
    test_sample = train_sample = zy_sample
    test_group = train_group = group
  }
  group_fact = unique(test_map[,test_group])
  if(isTRUE(discrete)){
    test_map[,test_group] = factor(test_map[,test_group], levels=group_fact)
    train_map[,train_group] = factor(train_map[,train_group], levels=group_fact)
  }
  train_dt = train_dt[, train_map[,train_sample]]
  X_train = t(train_dt)
  y_train = train_map[,group]
  
  test_dt  = test_dt[, test_map[, test_sample]]
  X_test = t(test_dt)
  y_test = test_map[,group]
  
  
  set.seed(seed)
  cvlasso = cv.glmnet(X_train ,y_train, alpha = 1, family = "binomial")
  
  best_lambda = cvlasso$lambda.min
  best_lasso_model <- glmnet(X_train, y_train, alpha = 1, lambda = best_lambda, family = "binomial")
  
  pred = as.data.frame(predict(best_lasso_model, newx = X_test, type = "response"))
  colnames(pred) = "pred_prob"
  
  roc_obj = roc(y_test, pred$pred_prob)
  
  if (roc_obj$auc > 0.5){
      
      best_threshold <- as.numeric(coords(roc_obj, "best", ret = "threshold"))
      class_order = levels(as.factor(y_train))
      
      pred$pred_lab = ifelse(pred$pred_prob > best_threshold, class_order[2], class_order[1])
      pred$seed = seed
      pred = merge(test_map[,c(zy_sample, group)], pred, by.x=zy_sample, by.y="row.names")
      return(pred)
  }else{
      message("auc = ", roc_obj$auc)
  }
}


zy_lasso_importance <- function(rf_dt=NA, rf_map=NA, 
                                zy_sample="zy_RF_temp_ID", group=NA, 
                                ntree=999, cross_n = 10,
                                nspecies = NA,
                                seed=123){
  
  rf_map[,group] = as.factor(rf_map[,group])
  
  X = t(rf_dt)
  y = rf_map[,group]
  
  cv_lasso <- cv.glmnet(X, y, alpha = 1, family = "binomial")
  best_lambda <- cv_lasso$lambda.min
  best_lasso_model <- glmnet(X, y, alpha = 1, lambda = best_lambda, family = "binomial")
  
  # 获取模型系数
  lasso_coefficients <- coef(best_lasso_model)
  
  # 转换为数据框，便于查看
  lasso_coefficients_df <- as.data.frame(as.matrix(lasso_coefficients))
  colnames(lasso_coefficients_df) <- c("Coefficient")
  
  # 显示非零系数的特征
  non_zero_coefficients <- lasso_coefficients_df[lasso_coefficients_df$Coefficient != 0, , drop = FALSE]
  print(non_zero_coefficients)
  
}


zy_lasso_two_class <- function(rf_dt=NA, rf_map=NA, 
                            zy_sample="zy_RF_temp_ID", group=NA, 
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
    dplyr::group_by(across({{group}})) %>%
    summarise(value=n()) %>%
    as.data.frame()
  
  g1 <- rf_map %>%
    filter(across({{group}})==gs[1,1]) %>%
    mutate(rf_temp_cross_n=rep(sample(1:cross_n), gs[1,2]/cross_n+1)[1:gs[1,2]])
  
  g2 <- rf_map %>%
    filter(across({{group}})==gs[2,1]) %>%
    mutate(rf_temp_cross_n = rep(sample(1:cross_n), gs[2,2]/cross_n+1)[1:gs[2,2]])
  
  rf_map = rbind(g1,g2)
  rf_map[,group] = as.factor(rf_map[,group])
  
  predict_result = list() # 储存预测的结果
  
  for(i in 1:cross_n){
    cat("\rcorss: ", i, " / ", cross_n)
    test_sample = rf_map[rf_map$rf_temp_cross_n == i,]
    test_dt = rf_dt[,test_sample[,zy_sample]]
    X_test = t(test_dt)
    y_test = test_sample[,group]
    
    
    train_sample = rf_map[rf_map$rf_temp_cross_n != i,]
    train_dt = rf_dt[,train_sample[,zy_sample]]
    X_train = t(train_dt)
    y_train = train_sample[,group]
    
    cvlasso = cv.glmnet(X_train ,y_train, alpha = 1, family = "binomial")
    best_lambda = cvlasso$lambda.min
    
    best_lasso_model <- glmnet(X_train, y_train, alpha = 1, lambda = best_lambda, family = "binomial")
    
    pred = as.data.frame(predict(best_lasso_model, newx = X_test, type = "response"))
    colnames(pred) = "pred_prob"
    
    # roc_obj = roc(y_test, pred$pred_prob)
    predict_result = append(predict_result, list(pred)) # 储存每个样本预测到的结果
    # if (roc_obj$auc > 0.5){
    #     
    #     best_threshold <- as.numeric(coords(roc_obj, "best", ret = "threshold"))
    #     class_order = levels(as.factor(y_train))
    #     
    #     pred$pred_lab = ifelse(pred$pred_prob > best_threshold, class_order[2], class_order[1])
    #     predict_result = append(predict_result, list(pred)) # 储存每个样本预测到的结果
    # }else{
    #     message("auc = ", roc_obj$auc)
    # }
  }
  predict_result <- do.call("rbind", predict_result)
  predict_result = merge(rf_map[,c(zy_sample, group)], predict_result, by.x=zy_sample, by.y="row.names")
  predict_result
}
