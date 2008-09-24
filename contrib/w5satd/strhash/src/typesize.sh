#! /bin/sh
set -e
FILE=conftest$$
cat >$FILE.c <<EOF
#include "conftest$$.h"
int main()
{
	TYPE t;
	return sizeof(t);
}
EOF
for i in "short" "int" "long " "unsigned short" "unsigned int" "unsigned long" \
	"long long" "unsigned long long" ; do 
  rm -f $FILE.o
  echo "typedef $i TYPE;" >$FILE.h
  if ./auto-compile.sh -c $FILE.c >/dev/null 2>/dev/null ; 
  then
    if ./auto-link.sh $FILE $FILE.o ; then
      # cannot fail anyway.
      if ./$FILE ; then 
	:
      else
	x=$?
	p=`echo $i | sed 's/ /_/g' | tr "[a-z]]" "[A-Z]"`
	echo "#define SIZEOF_$p $x"
      fi
    fi
  fi
done
rm -f $FILE.c $FILE.o $FILE $FILE.h
exit 0
