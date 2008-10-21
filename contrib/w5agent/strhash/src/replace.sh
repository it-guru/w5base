#! /bin/sh
# replace.sh func replacementsourcebasename linkerstuff
#
func="$1"
file="$2"
shift
shift

TESTFILE=conftest$$
cat >$TESTFILE.c <<EOF
int main() {
	return $func(1);
}
EOF

./auto-compile.sh -c $TESTFILE.c  2>/dev/null >/dev/null # die if failure
for i in "$@" ; do
  if ./auto-link.sh $TESTFILE $TESTFILE.o $i 2>/dev/null >/dev/null ; 
  then
    if test "x$i" = x ; then 
      :
    else
      echo "$i"
    fi
    rm -f $TESTFILE.c $TESTFILE.o $TESTFILE
    exit 0;
  fi
done
rm -f $TESTFILE.c $TESTFILE.o $TESTFILE
./auto-compile.sh -c "$file.c" && echo "$file.o"
