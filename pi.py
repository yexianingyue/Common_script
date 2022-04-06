#!/share/data1/software/miniconda3/bin/python
import re
import sys
import argparse
import time

"""
过滤条件参考：
Marine DNA Viral Macro- and Microdiversity from Pole to Pole
过滤规则大致如下：
    1、位点覆盖总深度 >= 10x
    2、等位基因至少有4个碱基支持
    3、突变频率 5%
计算核酸微观多样性, 而且非参考基因等位基因个数，正负链相加至少为4个
DP=， 作者说代表的真实深度，I16代表的是-Q过滤后的个数，
"""
def get_args():
    parser = argparse.ArgumentParser(description = __doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("-i", metavar="Input", type=str, help='the vcf file')
    parser.add_argument("-d", metavar='MinDepth', type=int, default=10, help='Min depth of the position \033[31m[default: 10]\033[0m')
    parser.add_argument("-r", metavar="cons", type=float, default=0.05, help='Variable frequency. \033[31m[default: 0.05]\033[0m')
    args = parser.parse_args()
    return args

def process():
    pass

def main(args):
    in_file = args.i
    MIN_CONS = args.r # 最小突变频率
    MIN_DP = args.d # 最小覆盖深度

    f = open(in_file, 'r')
    total_mutation_site = 0 # 总的突变位点个数
    total_allel = 0 # 总的等位基因的碱基个数
    total_dp = 0
    s = 0
    partent = re.compile("DP=(\d+);I16=(\d+),(\d+),(\d+),(\d+)")
    for line in f:
        if re.search("^##|^#CHROM|INDEL;IDV=", line):
            continue
        ps = partent.search(line).groups()
        DP, ref_std, ref_rev, allel_std, allel_rev = [int(x) for x in ps] # 因为正则匹配返回的是str，所以转成int
        # 该位点总深度小于10
        if DP < MIN_DP:
            continue
        allel = allel_std + allel_rev # 等位基因突变个数
        dp = ref_std + ref_rev + allel_std + allel_rev # 该位点真实的总深度（baseQ 过滤后的）
        #cons = allel/dp
        total_mutation_site += 1 # 突变位点个数

        # 这边计算cons
        if  dp < MIN_DP or  allel < 4 or allel/dp < MIN_CONS:
            continue
        total_allel += allel
        total_dp += dp
        s += (ref_std + ref_rev)/dp * allel/(dp - 1)
    f.close()   
    print(f"file: {in_file}\ttotal var: {total_mutation_site}\ts: {s}\ttotal allel: {total_allel}\ttotal DP: {total_dp}")

if __name__ == "__main__":
    args = get_args()
    main(args)
