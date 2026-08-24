set -e
assemble=$1
# GCF_000861825.2

a=`echo ${assemble:0:3}`
b=`echo ${assemble:4:3}`
c=`echo ${assemble:7:3}`
d=`echo ${assemble:10:3}`
e=`echo ${assemble:14:1}`

baseurl="https://ftp.ncbi.nlm.nih.gov/genomes/all/"
echo "${baseurl}$a/$b/$c/$d/$e"
