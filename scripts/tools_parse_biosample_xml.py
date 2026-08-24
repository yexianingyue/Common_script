#!/share/data1/software/miniconda3/bin/python3

import sys, gzip, re, os, bz2
from copy import deepcopy as dcp
from collections import OrderedDict
import re

if len(sys.argv) != 2:
    print(f"\n\tUsage:\t{sys.argv[0]} biosample_set.xml.gz > output\n")
    exit(127)

patterns = OrderedDict({
    "accession": re.compile('accession="(.*?)"'),
    "title":re.compile('<Title>(.*)</Title>'),
    "finishing strategy (depth of coverage)": re.compile('display_name="finishing strategy \(depth of coverage\)".*>(Level.*) Draft.*</Attribute>'),
    "collection_date": re.compile('display_name="collection date".*>(.*)</Attribute>'),
    "estimated_size": re.compile('display_name="estimated size".*>(.*)</Attribute>'),
    "project_type": re.compile('attribute_name="project_type".*>(.*)</Attribute>'),
    "host": re.compile('display_name="host".*>(.*)</Attribute>'),
    "broad-scale environmental context": re.compile('display_name="broad-scale environmental context".*>(.*)</Attribute>'),
    "local-scale environmental context": re.compile('display_name="local-scale environmental context".*>(.*)</Attribute>'),
    "host taxonomy ID": re.compile('display_name="host taxonomy ID".*>(.*)</Attribute>'),
    "source material identifiers": re.compile('display_name="source material identifiers".*>(.*)</Attribute>'),
    "environmental medium": re.compile('display_name="environmental medium".*>(.*)</Attribute>'),
    "sequencing method": re.compile('attribute_name="sequencing method".*>(.*)</Attribute>'),
    "isolation and growth condition": re.compile('display_name="isolation and growth condition".*>(.*)</Attribute>'),
    "environmental package": re.compile('display_name="environmental package".*>(.*)</Attribute>'),
    "isolation source": re.compile('display_name="isolation source".*>(.*)</Attribute>'),
    })

key_order = patterns.keys()
result = { k: "" for k in key_order }

def match_x (line):
    for k,v in patterns.items():
        match = v.search(line)
        if match:
            return ((k, match[1]))
    return((None,None))

f = gzip.open(f"{sys.argv[1]}", 'rt')
temp_result = dcp(result)

print("\t".join([x for x in key_order])) # 打印表头
for line in f:
    k,v = match_x(line.strip())
    if k == "accession" and temp_result['accession'] !="" :
        print("\t".join([temp_result[x] for x in key_order]))
        temp_result = dcp(result)
    if k:
        temp_result[k] = v
f.close()
