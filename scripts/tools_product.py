#!/share/data1/software/miniconda3/bin/python
import itertools
import sys

if sys.argv.__len__() != 4 or "-h" in sys.argv or "--help" in sys.argv:
    print("生成数据的排列组合")
    print("example: com -> 组合;  pro -> 排列")
    print(f"{sys.argv[0]} com/pro num '1,2,3'")
    exit(0)

if sys.argv[1] == "com":
    result = list(itertools.combinations(sys.argv[3].split(","), int(sys.argv[2])))
    for i in result:
        print(" ".join(i))
    exit(0)
    
result = list(itertools.product(sys.argv[3].split(","), repeat=int(sys.argv[2])))
for i in result:
    print(" ".join(i))
exit(0)
