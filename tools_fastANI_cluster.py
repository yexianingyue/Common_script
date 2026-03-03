#!/share/data1/software/miniconda3/envs/drep3/bin/python3
# -*- encoding: utf-8 -*-
##########################################################
# Creater       :  夜下凝月
# Created  date :  2024-03-20, 20:57:37
# Modiffed date :  2024-03-20, 20:57:38
##########################################################

import argparse
import logging

default_nc = 0.3
default_ani = 0.95
default_linkage = "average"

def get_args():
    parser = argparse.ArgumentParser(description = __doc__, formatter_class = argparse.RawTextHelpFormatter)
    parser.add_argument('-i', required=True, help='fastANI result.')
    parser.add_argument('-o', required=True, help="output file.")
    parser.add_argument('-nc', default=default_nc, type=float, help=f"similar with dRep -nc. [{default_nc}]")
    parser.add_argument('-ani', default=default_ani, type=float, help=f"ANI threshold. [{default_ani}]")
    parser.add_argument('-linkage_method', default=default_linkage, type=str, \
            choices=['average','ward','complete','single','median','weighted'], help=f"linkage method. [{default_linkage}]")
    args = parser.parse_args()
    return args


def main(ani_file, outf, cov_cut, ani_cut, linkage_method='average'):

    import pandas as pd
    import scipy
    import numpy as np
    import scipy.cluster
    from scipy.spatial import distance as ssd

    print(f"readfile:\t{ani_file}")
    df = pd.read_csv(ani_file, sep="\t", header=None)

    df.columns=['ref','query','ani', 'align','total']

    df['ani'] = df['ani']/100
    df['cov'] = df['align']/df['total']

    ### 矫正A-B, B-A 到同一个方向
    mask = df['ref'] > df['query']  # 找出 col1 大于 col2 的行
    df.loc[mask, ['ref', 'query']] = df.loc[mask, ['query', 'ref']].values  # 仅在这些行上交换 'col1' 和 'col2' 的值

    ## 过滤
    df.loc[df['cov'] <= cov_cut ,'ani'] = 0
    df.loc[df['ref']==df['query'],'ani'] = 1

    ## A-B 调换位置后，有两个值，求这两个的平均值，然后后再计算  距离 = 1 - ANI
    df = df.groupby(by=['ref','query'])['ani'].mean().to_frame('avg_ani').reset_index()
    df['dist'] = 1 - df['avg_ani']

    ## 距离矩阵
    dist = df.pivot('ref','query','dist')
    genomes_names = list(dist.columns)

    if dist.shape[0] != 1:

        upper_arr = np.triu(dist, k=1) # 获取上三角
        dist[np.isnan(upper_arr)] = 1 # 上三角的NA填充为1(不包括对角线), 因为有些基因组之间，可能没有ANI，所以将距离填充为最大
        dist = dist.fillna(0)

        dist = np.asarray(dist) # 将数据框转为矩阵
        np.fill_diagonal(dist, 0) # 对角线元素全部转为0


        low_arr = dist.T # 下三角矩阵
        arr = dist + low_arr # 对称矩阵
        arr = ssd.squareform(arr)

        ## 聚类
        linkage_cutoff = 1 - ani_cut

        print(f"Running:\tCluster")
        linkage = scipy.cluster.hierarchy.linkage(arr, method= linkage_method)
        fclust = scipy.cluster.hierarchy.fcluster(linkage, linkage_cutoff, criterion='distance')


        # 输出文件
        print(f"Output: \t{outf}")
        pd.DataFrame({'genomes':genomes_names,'cluster':fclust}) \
            .sort_values(by=['cluster'], ascending=[True]) \
            .to_csv(f"{outf}", sep="\t", index=None)
    else:
        pd.DataFrame({'genomes': genomes_names, 'cluster':1})\
            .to_csv(f"{outf}", sep="\t", index=None)

if __name__ == "__main__":
    args = get_args()
    main(args.i, args.o, args.nc, args.ani, args.linkage_method)
