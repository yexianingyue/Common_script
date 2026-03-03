#!/share/data1/zhangy2/conda/envs/py3.13/bin/python3
# 导入所需的库
import pandas as pd
from sklearn.ensemble import RandomForestRegressor
from sklearn.metrics import r2_score
from sklearn.model_selection import KFold
from scipy.stats import spearmanr
import logging
import argparse

__doc__ = """
    适用于连续变量挑选R2的值
"""
def get_args():
    parser = argparse.ArgumentParser(description=__doc__, formatter_class = argparse.RawTextHelpFormatter)
    parser.add_argument("-X", metavar="", required=True, help="matrix, features in rows, sample in columns")
    parser.add_argument("-Y", metavar="", required=True, help="metadata, sample in rows, factor in columns")
    parser.add_argument("-y", metavar="", required=True, help="Which factor to run")
    parser.add_argument("-o", metavar="", required=True, help="output prefix")
    
    # 特征值的设置
    parser.add_argument("--max_features", metavar="", default=100, type=int, help="挑选最大的特征数[\033[32m100\033[0m]")
    parser.add_argument("--max_corr", metavar="", default=0.6, type=float, help="特征值之间的最大相关系数绝对值[\033[32m0.6\033[0m].最终筛选出来的特征值，之间不允许任何相关系数超过这个阈值")
    parser.add_argument("--step", metavar="", default=1.01, type=float, help="new_R2/last_R2 < step [\033[32m1.01\033[0m]")
    parser.add_argument("--step_count", metavar="", default=10, type=int, help="如果连续[\033[32m10\033[0m]次，R2增长速率小于step则退出程序")
    
    # 随机森林设置
    parser.add_argument("-p", metavar="", default=-1, dest="threads",type=int, help="threads. [\033[0m-1\033[0m: means all]")
    parser.add_argument("--seed", metavar="", default=None, dest="seed",type=int, help="seed.[\033[32mNone\033[0m]")
    parser.add_argument("--nest", metavar="", dest="n_estimators", type=int, default=1000, help="决策树的数量.[\033[32m1000\033[0m]")
    parser.add_argument("--max_depth", metavar="", dest="max_depth", type=int, default=1000, help="树的最大深度.[\033[32mNone\033[0m]")
    
    parser.add_argument("--fold", metavar="", default=10, type=int,help="KF[\033[32m10\033[0m]")
    
    # 数据过滤条件
    parser.add_argument("--min_abundance", metavar="", default=0.01, type=float, help="prevalence num[\033[32m0.01\033[0m]")
    parser.add_argument("--min_prevalence", metavar="", default=3, type=int, help="最少有N个样本的丰度>=min_abundance[\033[32m3\033[0m]")
    
    # 读取数据的设置
    parser.add_argument("-s", metavar="", required=False, type=int,  default=1, choices=[0,1,2,3], help="Split Str fo matrix and group.[\033[32m1\033[0m] \033[31mThey must have similary split str\033[0m\n0 -> \\s+\n1 -> \\t\n2 -> |\n3 -> ,")
    parser.add_argument("-XT", metavar="", required=False, type=bool,  default=False, choices=[True, False], help="Transposite X [\033[32mFalse\033[0m]")
    parser.add_argument("-YT", metavar="", required=False, type=bool,  default=False, choices=[True, False], help="Transposite Y [\033[32mFalse\033[0m]")
    
    # deubg
    parser.add_argument("-level", metavar="", required=False, type=str, default="debug", choices=["info","debug", "warning","error"], help='log level: ["debug", "warining","error", "\033[32minfo\033[0m"]')
    args = parser.parse_args()
    return args
    
def get_overall_importance(X,y, nest=1000, seed=2024, threads=-1, max_depth=None):
    # seed = 2024
    # threads = -1
    # nest = 1000
    # max_depth = None
    # 获取重要性排序
    logging.debug(f"seed:{seed}")
    mod_all = RandomForestRegressor(
        n_estimators=nest,  # 决策树的数量
        random_state=seed,   # 随机种子，保证结果可复现
        max_depth=max_depth,    # 树的最大深度，默认不限
        min_samples_split=2,  # 内部节点再划分所需的最小样本数
        n_jobs=threads,
    )
    logging.debug("build overall module importance")
    mod_all.fit(X, y)

    important_features = pd.DataFrame({
        'Feature': X.columns,
        'Importance': mod_all.feature_importances_
    }).sort_values(by='Importance', ascending=False)
    return important_features

def add_feature(modules, target, X, cutoff=1):
    for i in modules:
        correlation, p_value = spearmanr(X[i], X[target])
        logging.debug(f"{correlation}")
        if abs(correlation) >= cutoff:
            return False
    modules.append(target)
    return True

def align_xy(df, y, min_abundance=0.01, min_prevalence=3):
    
    y = y.dropna() # 删除NA值
    
    intersect_id = df.columns.intersection(y.index)
    y = y[intersect_id]
    dff = df.reindex(columns=y.index)
    
    prevalence = (dff > min_abundance).sum(axis=1)
    X = dff[prevalence >= min_prevalence].T
    
    return X, y

def get_r2(X, y, fold=10, nest=1000, seed=2024, threads=-1, max_depth=None):
    # fold = 10
    # seed = 2025
    # threads = -1
    # nest = 1000
    # max_depth = None

    # 初始化 KFold，
    logging.debug(f"seed:{seed}")

    kf = KFold(n_splits=fold, shuffle=True, random_state=seed)

    # 初始化回归模型
    model = RandomForestRegressor(
        n_estimators=nest,  # 决策树的数量
        random_state=seed,   # 随机种子，保证结果可复现
        max_depth=max_depth,    # 树的最大深度，默认不限
        min_samples_split=2,  # 内部节点再划分所需的最小样本数
        n_jobs=threads,)

    # 存储每折的均方误差
    result = []
    count = 1
    for train_index, test_index in kf.split(X):
        logging.debug(f"fold: {count}")
        count += 1
        X_train, X_test = X.iloc[train_index,:], X.iloc[test_index,:]
        y_train, y_test = y.iloc[train_index], y.iloc[test_index]
        model.fit(X_train, y_train)
        y_pred = model.predict(X_test)
        res = pd.DataFrame({"true":y_test, "pred": y_pred})
        result.append(res)
    results = pd.concat(result)
    r2 = r2_score(results['true'], results['pred'])
    return r2

def main(args):
    sstr = {0:r"\s+", 1:r"\t", 2:r"\|", 3:","}[args.s]
    xf = args.X
    yf = args.Y
    meta = args.y
    outf = args.o

    min_prevalence = args.min_prevalence
    min_abundance = args.min_abundance
    
    ## select features
    m_max_corr = args.max_corr
    m_max_features = args.max_features
    m_step = args.step
    m_step_count = args.step_count
    
    ## random forest params
    rf_max_depth = args.max_depth
    rf_threads=args.threads
    rf_seed = args.seed
    rf_nest = args.n_estimators
    rf_fold = args.fold

    ## 文件读取参数
    xt = args.XT
    yt = args.YT

    def readf(inf, sstr, trans=False):
        logging.debug(f"read file {inf}")
        if sstr.strip() in ['\\s+', '\\s+', r'\s+', ' ', '\t', 'whitespace', ',', "\\|"]:
            # 统一处理为空白分隔
            if trans:
                return pd.read_csv(inf, delim_whitespace=True, index_col=0, header=0).T
            else:
                return pd.read_csv(inf, delim_whitespace=True, index_col=0, header=0)
        else:
            if trans:
                return pd.read_csv(inf, sep=sstr, index_col=0, header=0, engine='python').T
            else:
                return pd.read_csv(inf, sep=sstr, index_col=0, header=0, engine='python')


    # read file
    df = readf(xf, sstr, xt) ## read x profile
    metadata = readf(yf, sstr, yt) ## read y profile
    
    
    y = metadata[meta]
    X,y = align_xy(df,y, min_abundance, min_prevalence)

    overall_important = get_overall_importance(X, y, nest=rf_nest, seed=rf_seed, threads=rf_threads, max_depth=rf_max_depth)
    overall_important['meta'] = meta
    overall_important.to_csv(f"{outf}.overall_important.csv", index=False) # save importance

    features_all = overall_important['Feature'].to_list()
    
    modules = features_all[0:2]
    r2s = [None,]

    count = 0
    
    # 计算第2个开始的R2
    for i,v in enumerate(features_all[1:]):
        #  如果连续10次 R2/last_R2 < m_rise_rate就退出。因为这意味着会须只有很小的几率会增加了
        if count > m_step_count:
            break
        logging.info(f"features: - {i}")
        logging.info(f"modules: {len(modules)}")

        if i == 0:
            ## 第一次计算R2
            r2 = get_r2(X[modules], y, fold=rf_fold, nest=rf_nest, seed=rf_seed, threads=rf_threads, max_depth=rf_max_depth) # rf_fold, nest, seed, threads, max_depth = 10, 1000, 2025, -1, None
            last_r2 = r2

        elif len(modules) >= m_max_features: # m_max_features = 100
            ## 如果当前的特征数量超过了阈值就退出,默认100
            break
        else:

            if add_feature(modules, v, X, m_max_corr): # m_max_corr = 0.6
                r2 = get_r2(X[modules], y, fold=rf_fold, nest=rf_nest, seed=rf_seed, threads=rf_threads, max_depth=rf_max_depth) # rf_fold, nest, seed, threads, max_depth = 10, 1000, 2025, -1, None

                ## R2 是否增加
                if r2 >= last_r2:
                    logging.info(f"modules: {len(modules)}\t\tR2: {r2}")
                    logging.info(modules)
                    ## 如果增加了就看增加的趋势
                    if r2 / last_r2 < m_step:
                        count += 1
                    else:
                        count = 0
                    last_r2 = r2
                else:
                    ## 如果没增加，就继续测试下一个特征
                    modules.pop() # 不然的话删除上一个添加的物种
                    count += 1
                    continue
            else:
                continue
        r2s.append(r2)

    results = pd.DataFrame({"species": modules, "R2": r2s, 'y':meta})

    results.to_csv(f"{outf}.R2.csv", index=False) # save results




if __name__ == "__main__":
    args = get_args()
    logging_level = {"info":logging.INFO, "debug": logging.DEBUG, "warning":logging.WARNING, "error":logging.ERROR}.get(args.level)
    logging.basicConfig(level=logging_level, format="%(asctime)s - %(levelname)s - %(message)s")

    main(args)
