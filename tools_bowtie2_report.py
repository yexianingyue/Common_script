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
 
def parse_file(file_):
    f = open(file_, 'r')
    count = 0
    for line in f:
        if re.match("\s+(\d+) .* were paired; of these:"):
            total_reads = re.match("\s+(\d+) .* were paired; of these:").group[0]
        elif re.match("\s+(\d+) \(.*\) aligned concordantly 0 times"):
            concordantly_0 = re.match("\s+(\d+) \(.*\) aligned concordantly 0 times").group[0]
        elif re.match("\s+(\d+) \(.*\) aligned concordantly exactly 1 time"):
            concordantly_1 = re.match("\s+(\d+) \(.*\) aligned concordantly exactly 1 time").group[0]
        elif re.match("\s+(\d+) \(.*\) aligned concordantly >1 times"):
            concordantly_lt_1 = re.match("\s+(\d+) \(.*\) aligned concordantly >1 times").group[0]
        elif re.match("\s+(\d+) \(.*\) aligned discordantly 1 time"):
            discordantly_1 = re.match("\s+(\d+) \(.*\) aligned discordantly 1 time").group[0]
        elif re.match("\s+(\d+) pairs aligned 0 times concordantly or discordantly; of these:"):
            re.match("\s+(\d+) pairs aligned 0 times concordantly or discordantly; of these:").group[0]
        elif re.match("\s+(\d+) mates make up the pairs; of these:"):
            re.match("\s+(\d+) mates make up the pairs; of these:").group[0]
        elif re.match("\s+(\d+) \(.*\) aligned 0 times"):
            re.match("\s+(\d+) \(.*\) aligned 0 times").group[0]
        elif re.match("\s+(\d+) \(.*\) aligned exactly 1 time"):
            re.match("\s+(\d+) \(.*\) aligned exactly 1 time").group[0]
        elif re.match("\s+(\d+) \(.*\) aligned >1 times"):
            re.match("\s+(\d+) \(.*\) aligned >1 times").group[0]
        elif re.match("(\d+)% overall alignment rate"):
            re.match("\s+(\d+) \(.*\) aligned >1 times").group[0]


    print(f.read())
    f.seek(0)
    print(pattern.search(f.read()))
    f.close()

if __name__ == "__main__":

    if sys.argv.__len__() == 1 or "-h" in sys.argv or "--help" in sys.argv:
        print(f'{sys.argv[0]} <regular>  *.log')
        print(f'example:(suitable to paired reads)')
        print(f'{sys.argv[0]} "(.*).nohost.log"  *.log')
        exit(0)

    pattern = re.compile(f"{sys.argv[1]}")

    for f in sys.argv[2:]:
        parse_file(f)
