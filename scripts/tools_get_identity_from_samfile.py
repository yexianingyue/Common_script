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
    return identity


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
        identity = is_remain(flag = line_split[1], ncolumns = len(line_split), cigar = line_split[5], tags = line_split[-1], similar=0.97)
        print(f"{line_split[0]}\t{line_split[1]}\t{line_split[2]}\t{identity}")


if __name__ == "__main__":
    if sys.stdin.isatty():
        print("\n\t脚本接受标准输入或管道符输入")
        print("\t标准错误输出是每个位点的深度.如果没有重定向，则不会输出")
        print("\n\t标准输入:")
        print(f"\n\t\t{sys.argv[0]} <samfile prefix [ >output ] ")
        print("\n\t管道符:")
        print(f"\n\t\tcat samfile | {sys.argv[0]} prefix [ >output ]\n\n")
        exit(0)
    main()
    # cProfile.run('main()')
