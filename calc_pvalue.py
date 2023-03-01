#!/usr/bin/python3

from itertools import combinations
import pandas as pd
from scipy.stats import wilcoxon # 符号检验
from scipy.stats import mannwhitneyu # 结果完全对标R中的wilcox.test 默认参数
# from scipy.stats import ranksums #  秩和检验，但是统计量不太清楚给的是什么统计量
import argparse

'''
summary
'''

def calc_wilcox_pvalue(p_dt, p_map, sample="Sample", group="Group"):
    print("start calc")
    p_dt = p_dt.reindex(columns=p_map[sample])
    p_map = p_map.loc[:,[sample,group]].drop_duplicates()
    grps = p_map[group].unique()
    com = list(combinations(grps, 2)) # 迭代器只能循环一次，所以变为list
    nspecies = p_dt.shape[0]
    names_ = p_dt.index

    result = pd.DataFrame(index = range(0, nspecies*len(com)),
                    columns=["name","g1","g2",
                             "mean1","mean2","median1","median2",
                             "quantile1_1","quantile2_1","quantile1_2","quantile2_2",
                             "rank1.mean","rank2.mean","rank1.median","rank2.median",
                            "pvalue","fold_change","enriched"])
    index_ = 0

    for n in range(0, nspecies) :
        temp_dt = p_dt.iloc[n,:] # iloc 数字索引
        temp_dt_rank = temp_dt.rank()
        for c in com:
            g1, g2 = c
            g1s = p_map.loc[p_map.loc[:, group] == g1, sample]
            g2s = p_map.loc[p_map.loc[:, group] == g2, sample]
            dt1 = temp_dt.loc[g1s]
            dt2 = temp_dt.loc[g2s]
            m1 = dt1.mean()
            m2 = dt2.mean()
            median1 = dt1.median()
            median2 = dt2.median()
            quantile1_1 = dt1.quantile(0.25)
            quantile2_1 = dt2.quantile(0.25)
            quantile1_2 = dt1.quantile(0.75)
            quantile2_2 = dt2.quantile(0.75)

            # 对秩进行统计
            rank1 = temp_dt_rank.loc[g1s]
            rank2 = temp_dt_rank.loc[g2s]
            rank1_avg = rank1.mean()
            rank2_avg = rank2.mean()
            rank1_median = rank1.median()
            rank2_median = rank2.median()

            _, p = mannwhitneyu(dt1,dt2)
            mx = max(m1, m2)
            mi = min(m1, m2)
            fold_change = float("inf") if mi == 0 else mx/mi # 防止分母为0
            enriched = g1 if m1 > m2 else g2
            result.loc[index_,:] = [names_[n], g1, g2,
                                    m1, m2, median1, median2,
                                    quantile1_1,quantile2_1,quantile1_2,quantile2_2,
                                    rank1_avg, rank2_avg, rank1_median, rank2_median,
                                    p, fold_change, enriched]
            index_ += 1
    return result


def get_args():
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawTextHelpFormatter)
    parser.add_argument("-d", metavar="data", required=True, type=str, help="data table file")
    parser.add_argument("-g", metavar="group", required=True, type=str, help="sample group file")
    parser.add_argument("-n", metavar="id", type=str, help="ID of sample")
    parser.add_argument("-G", metavar="Group", type=str, help="Group of sample")
    parser.add_argument("-o", metavar="out", required=True, type=str, help="Output")
    args = parser.parse_args()
    return args

def main(in_d, in_map, out_f, sample="Sample", group="Group"):
    print("read table")
    dt = pd.read_csv(in_d, sep="\t", header=0, index_col=0,engine='python', encoding="unicode_escape")
    sample_map = pd.read_csv(in_map, sep="\t", header=0, engine='python', encoding="unicode_escape")
    print(f"nspecies of dt: {dt.shape[0]}")
    print(f"nsample of group: {sample_map.shape[0]}")
    result = calc_wilcox_pvalue(dt, sample_map, sample=sample, group=group)
    result.to_csv(out_f, sep="\t")

if __name__ == "__main__":
    args = get_args()
    main(in_d = args.d, in_map= args.g, sample=args.n, group=args.G, out_f=args.o)

