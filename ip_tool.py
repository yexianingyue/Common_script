#!/usr/bin/python3
import sys

def convert_ip(ip):
    ips = ip.split(".")
    ipb = []
    for i in ips:
        ipb.append(f"{int(i,10):08b}") # 十进制转二进制，且高位补零
    return " ".join(ipb)

def convert_binary(ipb:str, num):
    # 以空格分割的二进制
    x = num//8 # 因为之前的ip有空格，所以这边看看越过了多少位，添加空格
    num = num + x
    temp_ipb = "11111111 11111111 11111111 11111111"
    new_ipb = ipb[0:num+1] + temp_ipb[num:]
    ipbs = new_ipb.split(" ")
    ips = []
    for i in ipbs:
        ips.append(f"{int(i,2):d}")
    return  ".".join(ips)

def judge(ip1, ip2, num):
    # num 就是子网掩码数字,如127.0.0.1/10中的10
    x = num // 8 # 因为之前的ip有空格，所以这边看看越过了多少位，添加空格
    num = num + x
    ip1b = convert_ip(ip1)
    ip2b = convert_ip(ip2)
    print(f"{ip1b}\t{ip1}\n{ip2b}\t{ip2}")
    # 因为是取num个数字，索引从0开始，所以不用+1
    if ip1b[0:num] == ip2b[0:num]:
        print("OK")
    else:
        print("No")

def main():
    # 如果只有一个ip 
    if sys.argv.__len__() == 2:
        ip_temp = sys.argv[1]        
        # 是否携带了子网掩码信息
        if "/" in ip_temp:
            ip, num = ip_temp.split("/")
            ipb = convert_ip(ip)
            stop_ip = convert_binary(ipb, int(num))
            print(f"{ip_temp}:\t{ip} ~ {stop_ip}")
        else:
            ipb = convert_ip(ip_temp)
            print(f"{ipb}\t{ip_temp}")
    else:
        ip1 = sys.argv[1]
        ip2 = sys.argv[2]
        if "/" in ip1:
            ip1, num = ip1.split("/")
        elif "/" in ip2:
            ip2, num = ip2.split("/")
        judge(ip1, ip2, int(num))


if __name__ == "__main__":
    if sys.argv.__len__() > 3 or sys.argv.__len__() < 2:
        print(f"{sys.argv[0]} ip1 [ip2]")
        exit(127)
    main()
