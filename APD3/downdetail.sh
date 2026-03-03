id=$1
a="curl https://aps.unmc.edu/database/peptide  -X POST -d 'ID=${id}' -k > AP${id}.detail"
echo $a | sh
