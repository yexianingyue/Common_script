#!/share/data1/software/miniconda3/envs/bio38/bin/python
#/share/data1/software/miniconda3/bin/python
# -*- encoding: utf-8 -*-
##########################################################
# Creater       :  夜下凝月
# Created  date :  2023-10-12, 22:36:37
# Modiffed date :  2023-10-12, 22:36:37
##########################################################


import cProfile
import numpy as np
import re
import sys, os


CONTENT = [0,] # 是否是比对结果部分
CONTIG_ORDER = [] # 记录contig的顺序
CONTIG_DICT = {} # ctg2: [0,0,0,...], ctg2: [0,0,0,..] # 每条contig都根据长度，列出来所有的位点深度 changed in process_line.

PATTERN_READS_LEN = re.compile("(\d+)[M=XDI]") # fq_len = re.findall("(\d+)[M=XDI]", cigar)
PATTERN_MDTAG = re.compile("MD:Z:(\S+)")
PATTERN_POS = re.compile("(\d+|\^[A-Z]+|[A-Z]+)")
PATTERN_REF_LEN = re.compile("(\d+)[MDN=X]")
PATTERN_ERR_BASE = re.compile("\^") # 错配的碱基
PATTERN_MATCH_NUM = re.compile("(\d+)")
PATTERN_HEADER = re.compile("@SQ\tSN:(.*)\tLN:(\d+)")

def is_remain(flag=0, ncolumns=0, cigar="*", tags="", similar=0.97):
    '''
    aim:
        过滤不符合条件的比对记录
    return:
        (False, ) -> 去除
        (True, mdtag)  -> 保留，且返回MD:Z:标签

    tags: sam文件第11列以后的内容
    '''

    # 跳过没有匹配的记录
    if int(flag) & 0x4 != 0 :
        return (False, None)

    # 如果正好等于11列，那就说明整个sam文件没有最后的tag说明文档，直接报错退出
    if ncolumns == 11:
            sys.stderr.write("can't find tags in samfile.")
            exit(127)

    #------------------------------
    #       根据相似度过滤
    match_count = 0

    fq_len = PATTERN_READS_LEN.findall(cigar)
    fq_len = sum([int(x) for x in fq_len]) # 获取reads的长度

    # 获取正确匹配的碱基个数
    mdtag = PATTERN_MDTAG.search(tags)
    if not mdtag:
        return (False, None)
    # match_count = sum( [int(x) for x in re.findall(r'(\d+)', mdtag[1])] )
    match_count = sum( [int(x) for x in PATTERN_MATCH_NUM.findall(mdtag[1])] )

    # 计算相似度
    identity = match_count / fq_len
    if identity <= similar:
        return (False, None)

    return(True, mdtag[1])


def get_delete_pos(mdtag:str):
    pos = PATTERN_POS.findall(mdtag)
    step = -1
    delete_pos = []
    for x in pos:
        if x[0] != "^":
            try:
                step += int(x)
            except:
                step += len(x)
        elif x[0] == "^":
            for i in range(0,len(x)-1):
                step += 1
                delete_pos.append(step)
    return(delete_pos)

def calc_depth(CONTIG_DICT, ref_name:str, ref_pos:int, cigar:str, mdtag:str):
    '''
    sam文件中，所有的位点，都是从1开始的，所以对应到python中，都减去1
    '''
    # 获取参考序列的长度
    ref_len = PATTERN_REF_LEN.findall(cigar)
    ref_len = sum([int(x) for x in ref_len])
    ref_pos = np.arange(ref_pos - 1 ,ref_pos - 1 + ref_len, dtype=np.uint32)

    # 获取错误匹配的位点
    # if re.search("\^", mdtag):
    if PATTERN_ERR_BASE.search(mdtag):
        ref_delete = get_delete_pos(mdtag)
        ref_pos = np.delete(ref_pos, ref_delete)

    # x = ' '.join(ref_pos.astype('str'))
    # print(f"{x}")

    # 去除掉错误匹配的位点后，对正确位点进行加和
    CONTIG_DICT[ref_name][ref_pos] += 1


def print_depth(CONTIG_DICT, CONTIG_ORDER):
    if not os.isatty(sys.stderr.fileno()):
        stderr = 1
    else:
        stderr = 0
    print(f"contigName\tcontigLen\ttotalAvgDepth\t{sys.argv[1]}\t{sys.argv[1]}-var")
    # np.set_printoptions(threshold=np.inf, linewidth=np.inf, separator=' ')
    for ctg in CONTIG_ORDER:
        v = CONTIG_DICT[ctg]
        dep_sum = v[75:-75].sum()
        ctg_len = v.size
        if dep_sum != 0:
            dep_mean = round(dep_sum / (ctg_len - 150), 6)
            dep_var =  round(v[75:-75].var(ddof=1), 6)
        else:
            dep_mean = 0
            dep_var = 0
        print(f"{ctg}\t{ctg_len}\t{dep_mean}\t{dep_mean}\t{dep_var}")
        if stderr:
            sys.stderr.write(f">{ctg}\n")
            # print(v,file=sys.stderr)
            sys.stderr.write(" ".join(v.astype('str')) + "\n")
            # sys.stderr.write(f">{ctg}\n" + np.array2string(v,separator=" ", max_line_width=np.inf, threshold=np.inf)[2:-1]+"\n")
    # strx = '\n'.join(v[75:-75].astype('str'))
    # sys.stderr.write(strx)


def is_header(line, CONTENT, CONTIG_DICT, CONTIG_ORDER):
    if line.startswith("@SQ"):
        # ctg_name, ctg_len = re.match("@SQ\tSN:(.*)\tLN:(\d+)", line).groups()
        ctg_name, ctg_len = PATTERN_HEADER.match(line).groups()
        CONTIG_ORDER.append(ctg_name)
        CONTIG_DICT[ctg_name] = np.zeros(int(ctg_len), dtype=np.uint32)
    elif not line.startswith("@"):
        CONTENT[0] = 1
        return(False)
    return(True)


def main():
    global CONTIG_DICT
    global CONTENT
    global CONTIG_ORDER

    for line in sys.stdin:
        if CONTENT[0] == 0 and is_header(line, CONTENT, CONTIG_DICT, CONTIG_ORDER):
            continue
        line_split = line.strip().split("\t", 11)
        remain, mdtag = is_remain(flag = line_split[1], ncolumns = len(line_split), cigar = line_split[5], tags = line_split[-1], similar=0.97)
        if not remain:
            continue
        calc_depth(CONTIG_DICT, ref_name = line_split[2], cigar=line_split[5], ref_pos = int(line_split[3]), mdtag=mdtag)

    print_depth(CONTIG_DICT, CONTIG_ORDER)


if __name__ == "__main__":
    if sys.stdin.isatty():
        print("脚本接受标准输入或管道符输入")
        print("标准错误输出是每个位点的深度.如果没有重定向，则不会输出")
        print("标准输入:")
        print(f"{sys.argv[0]} <samfile prefix [ >output ] [ 2> contig.pos.dep]")
        print("管道符:")
        print(f"cat samfile | {sys.argv[0]} prefix [ >output ] [ 2> contig.pos.dep ]")
        exit(0)
    main()
    # cProfile.run('main()')
