w5satd : w5satd.o
	gcc  -l pthread -l mhash `curl-config --libs` -o w5satd w5satd.o ./strhash/src/libstrhash.a

w5satd.o : w5satd.c
	gcc -c -I /usr/include/curl -I /usr/include/mutils -I strhash/src -o w5satd.o w5satd.c

