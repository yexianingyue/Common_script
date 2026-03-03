#!/usr/bin/env python3
import pandas as pd
import sys
import numpy as np

if sys.argv.__len__()  != 4 or sys.argv[1] == "-h":
    print(f"\t{sys.argv[0]} strains.abundance  function.prfile output")
    print(f"\t\tstrains.abundance 行：细菌，列：样本")
    print(f"\t\tfunction.prfile   行：基因，列：细菌")
    exit()

in_m = sys.argv[1] # microbiome
in_f = sys.argv[2] # function
outf = sys.argv[3] # output file

print(f"readfile:\t{in_m}")
abun = pd.read_csv(in_m, index_col=0, header=0, sep="\t")
print(f"readfile:\t{in_f}")
anno = pd.read_csv(in_f, index_col=0, header=0, sep="\t")


cross_name = np.intersect1d(abun.index, anno.columns)

abun = abun.reindex(index=cross_name)
anno = anno.reindex(columns=cross_name)

res = anno.values @ abun.values
result_df = pd.DataFrame(res, index=anno.index, columns=abun.columns)

result_df.to_csv(outf, sep="\t", chunksize=500)
result_df.div(result_df.sum()).to_csv(f"{outf}.rela", sep="\t", chunksize=500)
