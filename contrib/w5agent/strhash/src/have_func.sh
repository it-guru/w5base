#! /bin/sh
#
# check for function $1.
# extra includes: $2
# $3 is how to call the function.
# extra linker arguments: $4
# extra libs: $5

set -e

fn="$1" ; shift
extraheader="$1" ; shift
call="$1" ; shift
extralink="$1" ; shift
libs="$1" ; shift
FN=`echo "$fn" | tr 'a-z' 'A-Z'`

FILE=conftest$$
DEFINE=undef

#
cat >$FILE.c <<EOF
#include <sys/types.h>
$extraheader
int main(void)
{
	$call
	;
	_exit(0);
}
EOF
if ./auto-compile.sh -c $FILE.c >&2 ; then
  for i in "" $libs ; do
    if test "x$i" = x ; then
      l=""
    else
      l="-l$i"
    fi
    # >&2 because we use the stdout of this script, and the MAC OS X linker
    # thinks the error messages belong on stdout.
    if ./auto-link.sh $FILE $FILE.o $extralink $l >&2 ; then
      if ./$FILE ; then
	DEFINE=define
      fi
    fi
  done
fi

cat <<EOF
#ifndef auto_have_${fn}_h
#define auto_have_${fn}_h
#$DEFINE HAVE_$FN /* systype-info */
#endif
EOF
rm -f $FILE $FILE.c $FILE.o
