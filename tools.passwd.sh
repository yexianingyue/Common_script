len=${1:-16}

a='0123456789abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!"#$%&\()*+,-./:;<=>?@[\]_{|}~'

echo $a | fold -w 1 | shuf -r | head -n ${len} | tr  -d '\n'
