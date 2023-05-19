#!/share/data1/software/miniconda3/bin/python
# -*- encoding: utf-8 -*-
##########################################################
# Creater       :  夜下凝月
# Created  date :  2021-03-05, 09:14:32
# Modiffed date :  2023-05-19, 14:29:31
##########################################################

'''
相关文件下载：
    必须文件：
        wget "https://ftp.ncbi.nlm.nih.gov/pub/taxonomy/taxdmp.zip" 这个文件当中储存了截至当前时间的所有物种分类的信息(必须文件)
        unzip taxdmp.zip

    非必须文件:
        利用下面的文件，你可以创建几乎所有的分类Table，但你也可以选择只创建你关注的
        https://ftp.ncbi.nlm.nih.gov/pub/taxonomy/accession2taxid/nucl_wgs.accession2taxid.gz"
        wget "https://ftp.ncbi.nlm.nih.gov/pub/taxonomy/accession2taxid/nucl_gb.accession2taxid.gz"
        wget "https://ftp.ncbi.nlm.nih.gov/pub/taxonomy/accession2taxid/prot.accession2taxid.FULL.gz"

    taxid_list:
        当中包含了你要寻找的fulltaxon的taxid，可以来自于上面的，也可以是你关注的个别的tax id

    自定义：
        支持自定义输出，你只需要修改init_taxo和init_taid就可以，init_taxo就是输出是每个分类的前缀
        init_taid就是来自于nodes.dmp当中的分类层级
'''

import sys
import re
import gzip
from copy import deepcopy as dcp


if sys.argv.__len__() != 4 or '-h' in sys.argv or '--help' in sys.argv or '-help' in sys.argv:
    print(__doc__)
    print(f"{sys.argv[0]}  <nodes.dmp>  <names.dmp> <taxid_list>")
    print(f"Output to stdout")
    exit(127)

temp_stat = 0
stat = 0

temp_dict = {}
temp_names_dict = {}
leaf_node = {}
init_taxo = {
        "superkingdom": "supk__",
        "kingdom": "k__",
        "phylum": "p__",
        "class": "c__",
        "order": "o__",
        "family": 'f__',
        'genus': 'g__',
        'species': 's__'
        }

init_taid = {
        "superkingdom": "",
        "kingdom": "",
        "phylum": "",
        "class": "",
        "order": "",
        "family": '',
        'genus': '',
        'species': ''
        }

# read nodes.dmp
f = open(sys.argv[1], 'r')

for line in f:
    line_split = re.split("\t\|\t", line.strip())
    child_node,parent_node, rank = line_split[0:3]
    temp_dict[child_node] = (parent_node, rank)
f.close()

# read name.dmp
f = open(sys.argv[2], 'r')
for line in f:
    if not re.search("scientific name", line):
        continue
    line_split = re.split("\t\|\t", line.rstrip("\n"))
    temp_names_dict[line_split[0]] = line_split[1]
f.close()

# read in_file

f = open(sys.argv[3], 'r')
for line in f:
    mm = line.strip()

    taxo = mm+"\t"
    s = mm

    temp_taxo_dict = dcp(init_taxo)
    temp_taid_dict = dcp(init_taid)
    while(True):
        temp_node = temp_dict.get(s)
        temp_name = temp_names_dict.get(s)
        temp_name = temp_name if temp_name != None else ""
        if s == "1" or temp_node == None:
            taxo += ";".join(temp_taxo_dict.values()) + "\t" + ";".join(temp_taid_dict.values())
            print(taxo)
            break
        temp_taxo = temp_taxo_dict.get(temp_node[1])
        if temp_taxo != None:
            temp_taxo_dict[temp_node[1]] += temp_name
            temp_taid_dict[temp_node[1]] = s
        s = temp_node[0]
        continue
f.close()



