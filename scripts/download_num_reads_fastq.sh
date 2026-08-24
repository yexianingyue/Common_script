wget -q  -O - $1 | gzip -d |perl -ne 'print "$_";die if $. == 8000000' > $2

