#!/share/data1/software/miniconda3/bin/python3
# -*- conding: utf-8 -*-

import argparse
import sys

INSTRUMENTs = ["454 GS", "454 GS 20", "454 GS FLX", "454 GS FLX Titanium", "454 GS FLX+", "454 GS Junior", "AB 310 Genetic Analyzer", "AB 3130 Genetic Analyzer", "AB 3130xL Genetic Analyzer", "AB 3500 Genetic Analyzer", "AB 3500xL Genetic Analyzer", "AB 3730 Genetic Analyzer", "AB 3730xL Genetic Analyzer", "AB 5500 Genetic Analyzer", "AB 5500xl Genetic Analyzer", "AB 5500xl-W Genetic Analysis System", "BGISEQ-50", "BGISEQ-500", "DNBSEQ-G400", "DNBSEQ-G400 FAST", "DNBSEQ-G50", "DNBSEQ-T7", "Element AVITI", "FASTASeq 300", "GENIUS", "GS111", "Genapsys Sequencer", "GenoCare 1600", "GenoLab M", "GridION", "Helicos HeliScope", "HiSeq X Five", "HiSeq X Ten", "Illumina Genome Analyzer", "Illumina Genome Analyzer II", "Illumina Genome Analyzer IIx", "Illumina HiScanSQ", "Illumina HiSeq 1000", "Illumina HiSeq 1500", "Illumina HiSeq 2000", "Illumina HiSeq 2500", "Illumina HiSeq 3000", "Illumina HiSeq 4000", "Illumina HiSeq X", "Illumina MiSeq", "Illumina MiniSeq", "Illumina NovaSeq 6000", "Illumina NovaSeq X", "Illumina iSeq 100", "Ion GeneStudio S5", "Ion GeneStudio S5 Plus", "Ion GeneStudio S5 Prime", "Ion Torrent Genexus", "Ion Torrent PGM", "Ion Torrent Proton", "Ion Torrent S5", "Ion Torrent S5 XL", "MGISEQ-2000RS", "MinION", "NextSeq 1000", "NextSeq 2000", "NextSeq 500", "NextSeq 550", "Onso", "PacBio RS", "PacBio RS II", "PromethION", "Revio", "Sentosa SQ301", "Sequel", "Sequel II", "Sequel IIe", "Tapestri", "UG 100", "unspecified"]
LIBRARY_SELECTIONs = ["RANDOM", "PCR", "RANDOM PCR", "RT-PCR", "HMPR", "MF", "repeat fractionation", "size fractionation", "MSLL", "cDNA", "cDNA_randomPriming", "cDNA_oligo_dT", "PolyA", "Oligo-dT", "Inverse rRNA", "Inverse rRNA selection", "ChIP", "ChIP-Seq", "MNase", "DNase", "Hybrid Selection", "Reduced Representation", "Restriction Digest", "5-methylcytidine antibody", "MBD2 protein methyl-CpG binding domain", "CAGE", "RACE", "MDA", "padlock probes capture method", "other", "unspecified"]
LIBRARY_SOURCEs = ["GENOMIC", "GENOMIC SINGLE CELL", "TRANSCRIPTOMIC", "TRANSCRIPTOMIC SINGLE CELL", "METAGENOMIC", "METATRANSCRIPTOMIC", "SYNTHETIC", "VIRAL RNA", "OTHER"]
LIBRARY_STRATEGYs = ["WGS", "WGA", "WXS", "RNA-Seq", "ssRNA-seq", "miRNA-Seq", "ncRNA-Seq", "FL-cDNA", "EST", "Hi-C", "ATAC-seq", "WCS", "RAD-Seq", "CLONE", "POOLCLONE", "AMPLICON", "CLONEEND", "FINISHING", "ChIP-Seq", "MNase-Seq", "Ribo-Seq", "DNase-Hypersensitivity", "Bisulfite-Seq", "CTS", "MRE-Seq", "MeDIP-Seq", "MBD-Seq", "Tn-Seq", "VALIDATION", "FAIRE-seq", "SELEX", "RIP-Seq", "ChIA-PET", "Synthetic-Long-Read", "Targeted-Capture", "Tethered Chromatin Conformation Capture", "OTHER"]


def get_args():
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawTextHelpFormatter)
    parser.add_argument("-i", required=True, help="name - reads")
    parser.add_argument("-m", required=True, help="sample - name")
    parser.add_argument("-p", required=True, help="Project")
    parser.add_argument("-o", required=True, help="outpue dir.")
    parser.add_argument("-INSTRUMENT", required=False, default="Illumina NovaSeq 6000", help="default: Illumina NovaSeq 6000")
    parser.add_argument("-LIBRARY_SOURCE" , choices=LIBRARY_SOURCEs, default="METAGENOMIC", help="default: METAGENOMIC")
    parser.add_argument("-LIBRARY_SELECTION", choices=LIBRARY_SELECTIONs, default="RANDOM", help="default: RANDOM")
    parser.add_argument("-LIBRARY_STRATEGY", choices=LIBRARY_STRATEGYs, default="WGS", help="WGS")
    args = parser.parse_args()
    return args


def parse_reads_list(inf):
    res = {}
    f = open(inf, 'r')
    for line in f:
        linef = line.strip().split("\t")
        res[linef[0]] = {}
        tmp = res[linef[0]]
        tmp['NAME'] = linef[0]
        tmp['FASTQ'] =  "\n".join(["FASTQ\t" + x for x in linef[1:]])
    f.close()
    return res

def  parse_sample_name(inf, res):
    f = open(inf, 'r')
    for line in f:
        linef = line.strip().split("\t")
        res[linef[1]]['SAMPLE'] = linef[0]
    f.close()

def write_result(ouf, content):
    with open(ouf, 'x') as f:
        f.write(content)

def main(args):
    perattr = ['NAME','SAMPLE']
    fixattr = f"STUDY\t{args.p}\nINSTRUMENT\t{args.INSTRUMENT}\nLIBRARY_SOURCE\t{args.LIBRARY_SOURCE}\nLIBRARY_SELECTION\t{args.LIBRARY_SELECTION}\nLIBRARY_STRATEGY\t{args.LIBRARY_STRATEGY}\n"

    res_map = parse_reads_list(args.i)
    parse_sample_name(args.m, res_map)
    for name,res in res_map.items():
        tmp_res = ""
        for attr in perattr:
            tmp_res += f"{attr}\t" + res[attr] + "\n"
        tmp_res += fixattr + res['FASTQ'] + "\n"
        write_result(f"{args.o}/{name}.list", tmp_res)


if __name__ == "__main__":
    args = get_args()
    main(args)
