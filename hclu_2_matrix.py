#!/share/data1/software/miniconda3/envs/bio38/bin/python
# -*- encoding: utf-8 -*-
##########################################################
# Creater       :  夜下凝月
# Created  date :  2020-03-25, 13:32:56
# Modiffed date :  2020-03-25, 13:32:56
##########################################################
import argparse
import re
import sys
import copy


def get_args():
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawTextHelpFormatter)
    parser.add_argument("-i", required=True, metavar="Hclu table", help="the hcluster_sg -c result")
    parser.add_argument("-o", required=True, metavar="Output", help="Output file")
    parser.add_argument("-b", default=0,     metavar="binary", type=int, choices=[0,1], help="Whether to output binary format(1/0:deafult)")
    parser.add_argument("-list", required=True,
                        metavar="list",
                        help="example\nstrain_1\nstrain_2")
    parser.add_argument("--regexp", required=False, metavar="regular expretion",
                        type=str,
                        help="example: \n\"(.*)_\d+_\d+\"\n\"(.*)_\d+ xxx\"")
    args = parser.parse_args()
    return args

def get_matrix_head(file_):
    """创建字典{菌株1：1， 菌株2：2, ...}"""
    head = {}
    f = open(file_, 'r')
    for index, line in enumerate(f):
        head[line.strip()] = index
    f.close()
    return head

def parser_genes_num(genes, title, row_matrix, regexp):
    '''解析hclu当中的ids，根据title字典，把对应的family中的菌数字改为1'''
    # partern = re.compile(r"clu_\d+\|([^, ]+)_\d+")
    if  regexp:
        partern = re.compile(regexp)
    else:
        partern = re.compile(r"([^,]+)_\d+,")
    genes_list = partern.findall(genes)
    #print(genes_list)
    for gene in genes_list:
        row_matrix[title[gene]] += 1
    row_matrix = [str(x) for x in row_matrix]
    return "\t".join(row_matrix)

def parser_genes_binary(genes, title, row_matrix, regexp):
    '''解析hclu当中的ids，根据title字典，把对应的family中的菌数字改为1'''
    # partern = re.compile(r"clu_\d+\|([^, ]+)_\d+")
    if  regexp:
        partern = re.compile(regexp)
    else:
        partern = re.compile(r"([^,]+)_\d+,")
    genes_list = partern.findall(genes)
    #print(genes_list)
    for gene in genes_list:
        row_matrix[title[gene]] = "1"
    return "\t".join(row_matrix)

def main(input_file, output_file, title, regexp, format_):

    if format_:
        init_row = ["0"]*len(title)
        parser_genes = parser_genes_binary
    else:
        init_row = [0]*len(title)
        parser_genes = parser_genes_num

    out = open(output_file, 'w')
    f = open(input_file, 'r')
    out.write("{}\t{}\n".format('familys', "\t".join(title)))
    family = 1
    for index, line in enumerate(f):
        genes = re.split(r"\s+", line.strip())[-1]
        row = parser_genes(genes, title, copy.deepcopy(init_row), regexp)
        out.write("family_{}\t{}\n".format(family, row))
        family += 1
    f.close()
    out.close()



if __name__ == "__main__":
    args = get_args()
    print(args.regexp)

    title = get_matrix_head(args.list)
    main(args.i, args.o, title, args.regexp, args.b)
