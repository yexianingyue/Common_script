library(mediation)

zy_mediation <- function(dt, x, y, m, sims=10, help=NULL){
    res = data.frame(matrix(NA, nrow=1, ncol=19,
                            dimnames = list(NULL,
                                            c("y","x","m",
                                              "y~x.est", "y~x.pvalue",
                                              "m~x.est", "m~x.pvalue",
                                              "y~x+m.est.x", "y~x+m.pvalue.x",
                                              "y~x+m.est.m", "y~x+m.pvalue.m",
                                              "acme","acme.p",
                                              "ade","ade.p",
                                              "total_effect", "total_effect.p",
                                              "prop.mediated","prop.mediated.p"))), check.names=F)
    
    '
    y, x, m 分别代表了应变量，自变量，中介变量
    
    y~x.est 表示x对y的解释方差，y~x.p 表示pvalue
    y~m.est 表示m对y的解释方差，y~m.p 表示pvalue
    
    y~x+m.est.x, 表示x和m一起解释y时，x对y的解释方差， y~x+m.pvalue.x 代表pvalue
    y~x+m.est.m, 表示x和m一起解释y时，m对y的解释方差， y~x+m.pvalue.m 代表pvalue
    
    acme，这个是自变量对因变量的间接作用，注意它是由自变量对中介变量的作用和中介变量对因变量的作用相乘得到的(m~x.est) * (y~x+m.est.m)。
    ade，这个是自变量对因变量的直接效应，也就是控制了中介变量后，自变量对因变量的效应。"y~x+m.est.x"
    total_effect. 这个就是总效应，也就是直接效应加间接效应 acme + ade
    prop.mediated.这个是中介效应的占比，是用间接效应除以总效应得到的。acme/(acme+ade)
    
    '
    
    # x是否是通过m对y起作用(完全中介，部分中介，直接效应，无)
    
    tmp_dt = dt[,c(x,y,m)]
    colnames(tmp_dt) = c("x","y","m")
    
    res[1,1:3] = c(y,x,m)
    # step.1 计算自变量和应变量之间的关系 y ~ x
    # 这一步可以没有显著性
    yx = lm(y ~ x, data=tmp_dt )
    summ = summary(yx)
    est = summ$coefficients[2,1]
    pval = summ$coefficients[2,4]
    res[1,4:5] = c(est, pval)
    
    
    # step.2 计算自变量和中介变量之间的关系 m ~ x
    # 理论上，这一步必须显著，因为如果自变量没有显著影响中介变量，那就没有意义
    mx = lm(m ~ x, data=tmp_dt )
    summ = summary(mx)
    est = summ$coefficients[2,1]
    pval = summ$coefficients[2,4]
    res[1,6:7] = c(est, pval)
    
    # step.3 计算自变量+中介变量对 应变量之间的关系 y ~ x + m
    # 这一步中，中介变量必须也显著，而且方程的解释度（相比只有自变量）必须更大才好
    # 如果这一步中，自变量对应变量也很显著，那就是部分中介。
    # 如果之一部，自变量对于应变量不显著，结合上一步(自变量对中介变量的显著)那就是完全中介
    yxm = lm(y ~ x + m, data=tmp_dt )
    summ = summary(yxm)
    x.est = summ$coefficients[2,1]
    x.pval = summ$coefficients[2,4] # 如果显著那就是部分中介，否则就是完全中介
    m.est = summ$coefficients[3,1]
    m.pval = summ$coefficients[3,4] # 必须显著，不然就意味着中介对应变量没有影响
    res[1,8:11] = c(x.est, x.pval, m.est, m.pval)
    
    
    # step.4 拟合系数估计和效应对比
    med = mediate(mx, yxm, treat="x", mediator="m", boot=T, sims = sims)
    summ = summary(med)
    
    acme_treated = summ$d1 # 自变量对应变量的间接作用【前两部的】
    acme_treated.p = summ$d1.p
    
    ade_treated = summ$z1 # 自变量对应变量的直接作用
    ade_treated.p = summ$z1.p
    
    total_effect = summ$tau.coef # 总效应，直接效应+间接效应 acme + ade
    total_effect.p = summ$tau.p
    
    prop_mediated = summ$n1 # 中介效应占比
    prop_mediated.p = summ$n1.p
    
    res[1,12:19] = c(acme_treated, acme_treated.p,
                     ade_treated, ade_treated.p,
                     total_effect, total_effect.p,
                     prop_mediated, prop_mediated.p
    )
    res
    
}
