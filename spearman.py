#!/usr/bin/python3

from scipy import stats
import numpy as np
import pandas as pd
import argparse
import sys


def main(in1, in2, out_f):

    print(f"read files: {in1}, {in2}")
    df1 = pd.read_csv(in1, sep="\t",header=0,index_col=0)
    df2 = pd.read_csv(in2, sep="\t", header=0, index_col=0)

    # align column names
    df2 = df2.reindex(columns=df1.columns)
    dt1 = df1.rank(axis=1)
    dt2 = df2.rank(axis=1)

    nrow1 = dt1.shape[0]
    nrow2 = dt2.shape[0]

    f = open(out_f, "w")

    otus1 = dt1.index
    otus2 = dt2.index

    f.write("name_a\tname_b\tcorr\tpvalue\n")
    for i in range(0,nrow1):
        for j in range(0,nrow2):
            s = stats.pearsonr(dt1.iloc[i,:], dt2.iloc[j,:])
            temp_str = f"{otus1[i]}\t{otus2[j]}\t{s[0]}\t{s[1]}\n"
            f.write(temp_str)
    f.close()

def get_args():
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawTextHelpFormatter)
    parser.add_argument("-i", metavar="matrix_1", required=True, type=str, help="Output")
    parser.add_argument("-I", metavar="matrix_2", required=True, type=str, help="Output")
    parser.add_argument("-o", metavar="out", required=True, type=str, help="Output")
    args = parser.parse_args()
    return args



if __name__ == "__main__":
    args = get_args()
    main(in1 = args.i, in2= args.I, out_f=args.o)
