#!/share/data1/software/miniconda3/bin/python3
import re
import sys
patterns = {
        1:"(\d+) reads; of these:",
        3:"(\d+) \(.*\) aligned concordantly 0 times",
        4:"(\d+) \(.*\) aligned concordantly exactly 1 time",
        5:"(\d+) \(.*\) aligned concordantly >1 times",
        6:"----",
        7:"(\d+) pairs aligned concordantly 0 times; of these:",
        8:"(\d+) \(.*\) aligned discordantly 1 time",
        9:"----",
        10:"(\d+) pairs aligned 0 times concordantly or discordantly; of these:",
        11:"(\d+) mates make up the pairs; of these:",
        12:"(\d+) \(.*\) aligned 0 times",
        13:"(\d+) \(.*\) aligned exactly 1 time",
        14:"(\d+) \(.*\) aligned >1 times",
        15:"(\d+)% overall alignment rate"}
 
def parse_file(file_, f_name):
    f = open(file_, 'r')
    count = 0
    total_reads, map_rate = 0, 0
    for line in f:
        linef = line.rstrip()
        if re.match("\s+(\d+).*were paired; of these:", linef):
            total_reads = re.match("\s+(\d+) .* were paired; of these:", linef).groups()[0]
        elif re.match("\s+(\d+) \(.*\) aligned concordantly 0 times", linef):
            concordantly_0 = re.match("\s+(\d+) \(.*\) aligned concordantly 0 times", linef).groups()[0]
        elif re.match("\s+(\d+) \(.*\) aligned concordantly exactly 1 time", linef):
            concordantly_1 = re.match("\s+(\d+) \(.*\) aligned concordantly exactly 1 time", linef).groups()[0]
        elif re.match("\s+(\d+) \(.*\) aligned concordantly >1 times", linef):
            concordantly_lt_1 = re.match("\s+(\d+) \(.*\) aligned concordantly >1 times", linef).groups()[0]
        elif re.match("\s+(\d+) \(.*\) aligned discordantly 1 time", linef):
            discordantly_1 = re.match("\s+(\d+) \(.*\) aligned discordantly 1 time", linef).groups()[0]
        elif re.match("\s+(\d+) pairs aligned 0 times concordantly or discordantly; of these:", linef):
            re.match("\s+(\d+) pairs aligned 0 times concordantly or discordantly; of these:", linef).groups()[0]
        elif re.match("\s+(\d+) mates make up the pairs; of these:", linef):
            re.match("\s+(\d+) mates make up the pairs; of these:", linef).groups()[0]
        elif re.match("\s+(\d+) \(.*\) aligned 0 times", linef):
            re.match("\s+(\d+) \(.*\) aligned 0 times", linef).groups()[0]
        elif re.match("\s+(\d+) \(.*\) aligned exactly 1 time", linef):
            re.match("\s+(\d+) \(.*\) aligned exactly 1 time", linef).groups()[0]
        elif re.match("\s+(\d+) \(.*\) aligned >1 times", linef):
            re.match("\s+(\d+) \(.*\) aligned >1 times", linef).groups()[0]
        elif re.match(".*overall alignment rate", linef):
            map_rate = re.match("(.*?)% overall alignment rate", linef).groups()[0]

    f.close()
    print(f"{f_name}\t{total_reads}\t{map_rate}")

if __name__ == "__main__":

    if sys.argv.__len__() == 1 or "-h" in sys.argv or "--help" in sys.argv:
        print(f'{sys.argv[0]} <regular>  *.log')
        print(f'example:(suitable to paired reads)')
        print(f'{sys.argv[0]} "(.*).nohost.log"  *.log')
        exit(0)

    pattern = re.compile(f"{sys.argv[1]}")

    for f in sys.argv[2:]:
        f_name = pattern.match(f).groups()[0]
        parse_file(f, f_name)
