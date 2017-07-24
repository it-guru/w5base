#!/bin/bash
for a in *.COMPRESSED.*; do 
   o=$(echo $a | sed -e 's/\.COMPRESSED//') 
   java -jar ../../contrib/javascript-compressor/yuicompressor-2.4.2/build/yuicompressor-2.4.2.jar $o > $a 
done
