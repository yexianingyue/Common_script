set -e
assemble=$1
assembly_name=`echo $2 | sed 's/_[_]*/_/g'`
# GCF_000861825.2

a=`echo ${assemble:0:3}`
b=`echo ${assemble:4:3}`
c=`echo ${assemble:7:3}`
d=`echo ${assemble:10:3}`

baseurl="https://ftp.ncbi.nlm.nih.gov/genomes/all/"
echo "${baseurl}$a/$b/$c/$d/${assemble}_${assembly_name}/"
