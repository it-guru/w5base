#!/bin/bash
for a in `ls *.jpg| grep -v '\.thumpnail\.'`; do
   echo "Process: $a"
   N=`echo "$a" | sed -e 's/\.jpg$/.thumpnail.jpg/i'`
   cat $a | jpegtopnm | pnmscale -width 200 | pnmtojpeg> $N
done
