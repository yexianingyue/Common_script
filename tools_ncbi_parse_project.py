#!/share/data1/software/miniconda3/envs/html/bin/python
# -*- encoding: utf-8 -*-
##########################################################
# Creater       :  夜下凝月
# Created  date :  2022-09-12, 16:48:04
# Modiffed date :  2022-09-12, 16:48:04
##########################################################
from bs4 import BeautifulSoup as bs
import argparse
import re
"""
extract information from the web of NCBI project
"""

def get_args():
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawTextHelpFormatter)
    parser.add_argument('-i', metavar='if', type=str, help='file')
    parser.add_argument("-t", metavar="title", default=True, type=bool, help="wether print title")
    args = parser.parse_args()
    return args

def main(in_f):

    f = open(in_f, 'r')
    soup = bs(f,'html.parser')

    # project
    project_id = re.search("Accession: (\S+)", soup.find(class_="rprt").find(class_="Right").text)[1]

    # 文章介绍
    introduction = soup.find(id='DescrAll').text
    introduction = re.sub("\n"," ", introduction)

    # project 标题
    title = soup.find(class_="rprt").h3.text

    # SRA experiments
    sra = soup.find(class_="FrameGrid").find(class_="smallIndent").text

    # SRA experiments number
    num_of_sra = soup.find(class_="FrameGrid").find(class_="RegularLink").text

    # SIZE
    temp_list = [ x.text for x in soup.find_all(class_='jig-ncbigrid')[-1].find_all("td")]
    ## Gb
    sra_size_Gb = temp_list[1]
    ## Mb
    sra_size_Mb = temp_list[3]

    print(f"{project_id}\t{num_of_sra}\t{sra_size_Gb}\t{sra_size_Mb}\t{title}\t{introduction}")


if __name__ == "__main__":
    args = get_args()
    if args.t:
        print(f"project_id\tnum_of_sra\tsra_size(Gb)\tsra_size(Mb)\ttitle\tintroduction")
    main(args.i)
