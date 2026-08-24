#!/share/data1/software/miniconda3/envs/html/bin/python
# -*- encoding: utf-8 -*-
##########################################################
# Creater       :  夜下凝月
# Created  date :  2023-02-07, 10:35:42
# Modiffed date :  2023-02-07, 10:35:42
##########################################################
'''
print_id_len.py <fasta_file>  > output
'''
from bs4 import BeautifulSoup
import sys
import re

def main():
    apdid = re.search("(AP\d+)", sys.argv[1])[0]
    with open(f"{sys.argv[1]}",'r') as f:
        c = f.read()
    soup = BeautifulSoup(c,'lxml')
    tb = soup.find("table")
    for i in tb.findAll("tr"):
        j = i.findAll("td")
        print(f"{apdid}\t{j[0].text.strip()}\t{j[1].text.strip()}")

if __name__ == "__main__":
    if sys.argv.__len__() == 1 or sys.argv.__len__() > 3 :
        print(f"{sys.argv[0]} APfile")
        exit(0)
    main()


