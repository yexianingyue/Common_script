#!/share/data1/software/miniconda3/bin/python3
# -*- encoding: utf-8 -*-
##########################################################
# Creater       :  夜下凝月
# Created  date :  2024-03-20, 20:57:37
# Modiffed date :  2024-03-20, 20:57:38
##########################################################

import argparse
import logging

def get_args():
    parser = argparse.ArgumentParser(description = __doc__, formatter_class = argparse.RawTextHelpFormatter)
    parser.add_argument('-i', required=True, help='mash result.')
    parser.add_argument('-o', required=True, help="output file.")
    parser.add_argument('-ani', default=0.95, type=float, help='ANI threshold. [0.95]')
    parser.add_argument('-linkage_method', default="average", type=str, \
            choices=['average','ward','complete','single','median','weighted'], help='linkage method. [average]')
    args = parser.parse_args()
    return args


def main(ani_file, outf, ani_cut, linkage_method='average'):

    import pandas as pd
    import scipy
    import numpy as np
    import scipy.cluster
    from scipy.spatial import distance as ssd

    print(f"readfile:\t{ani_file}")
    df = pd.read_csv(ani_file, sep="\t", header=None, usecols=[0,1,2])

    df.columns=['ref','query','dist']

    ## 距离矩阵
    print(f"转置矩阵")
    dist = df.pivot('ref','query','dist').fillna(1).astype(np.float32)
    genomes_names = list(dist.columns)
    if dist.shape[0] == 1:
        pd.DataFrame({'genomes':genomes_names, 'cluster': 1})\
            .to_csv(f"{outf}", sep="\t", index=None)
    else:

        dist = ssd.squareform(dist)

        ## 聚类
        linkage_cutoff = 1 - ani_cut

        linkage = scipy.cluster.hierarchy.linkage(dist, method= linkage_method)
        fclust = scipy.cluster.hierarchy.fcluster(linkage, linkage_cutoff, criterion='distance')
        print(f"Running:\tCluster")
        print(f"Output: \t{outf}")
            # 输出文件
        pd.DataFrame({'genomes':genomes_names,'cluster':fclust}) \
            .sort_values(by=['cluster'], ascending=[True]) \
            .to_csv(f"{outf}", sep="\t", index=None)

if __name__ == "__main__":
    args = get_args()
    main(args.i, args.o, args.ani, args.linkage_method)
