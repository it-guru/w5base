#! /bin/sh

# Note: echo on many systems (many BSDs, at least) does not return an
# error code.  Using echo is therefore now a really good idea.

set -e

MYCFLAGS=
MYLDFLAGS=
MYCC=
MYLD=
MYAR=
MYRANLIB=
MYLIBS=

gcctest() {
  if $1 --version /dev/null 2>&1 |head -1 |egrep '^(egcs|gcc)' >/dev/null ; then
    echo 1
  else
    echo 0
  fi
}
finish_script() { # finish_script basename
  _T="auto-$1.sh.t" # tmp
  _F="auto-$1.sh"   # final
  chmod +x "$_T"
  if test -f "$_F" ; then
    if cmp "$_T" "$_F" ; then
      rm -f "$_T"
    else
      mv "$_T" "$_F"
    fi
  else
    mv "$_T" "$_F"
  fi
}

cc_is_gcc=0
if test -f conf-cc ; then :
  MYCC="`cat conf-cc`"
  cc_is_gcc=`gcctest "$MYCC"`
else	
  MYCC=gcc
  cc_is_gcc=1
fi

if test -f conf-ld ; then 
  MYLD="`cat conf-ld`"
else 
  if test -f conf-cc ; then
    MYLD="`cat conf-cc`"
  else 
    MYLD="$MYCC"
  fi
fi
ld_is_gcc=`gcctest "$MYLD"`

if test -f conf-cflags ; then
  MYCFLAGS="`cat conf-cflags`"
else
  if test $cc_is_gcc = 1 ; then 
    if test "x$_CFLAGS_OG" = x ; then
      MYCFLAGS="-O2"
    else
      MYCFLAGS="$_CFLAGS_OG"
    fi
  else
    MYCFLAGS="-O"
  fi
fi

# cflags with warnings
if test -f conf-cflagsw ; then
  MYCFLAGSW="`cat conf-cflagsw`"
else
  if test -f conf-cflags ; then
    MYCFLAGSW="`cat conf-cflags`"
  else
    if test $cc_is_gcc = 1 ; then 
      if test "x$_CFLAGS_OWG" = x ; then
	MYCFLAGSW="-O2 -Wall -W"
      else
	MYCFLAGSW="$_CFLAGS_OWG"
      fi
    else
      MYCFLAGSW="-O"
    fi
  fi
fi

# ldflags
if test -f conf-ldflags ; then 
  MYLDFLAGS="`cat conf-ldflags`"
else
  if test $ld_is_gcc = 1 ; then
    MYLDFLAGS="-g3"
  else
    MYLDFLAGS="-g"
  fi
fi

# AR
if test -f conf-ar ; then 
  MYAR="`cat conf-ar`"
else
  MYAR=ar
fi

# ranlib
if test -f conf-ranlib ; then 
  MYRANLIB="`cat conf-ranlib`"
else
  MYRANLIB=ranlib
fi
if test -f conf-libs ; then 
  MYLIBS="`cat conf-libs`"
fi

#
# do we need large file support?
#
lfs() {
  >auto-systype.lfs
  cat >conftest-$$.c <<EOF
#include <sys/types.h>
#include <stdio.h>
int main(void)
{
  off_t x=0;
  printf("%d\n",8*sizeof(x));
  return 0;
}
EOF
  $MYCC $MYCFLAGS -c conftest-$$.c # set -e cares for errors.
  $MYLD $MYLDFLAGS -o conftest-$$ conftest-$$.o # dito.
  x=`./conftest-$$`
  rm -f conftest-$$ conftest-$$.*
  if test "$x" -ge 64 ; then
    echo '#define LARGE_FILE_SUPPORT "SYSTEM-INTERFACE" /* systype-info */' \
      >auto-systype.lfs
    return
  fi
cat >conftest-$$.c <<EOF
#define _LARGEFILE_SOURCE
#define _FILE_OFFSET_BITS 64
#include <sys/types.h>
#include <stdio.h>
int main(void)
{
  off_t x=0;
  if (sizeof(x)>=8)
    return 0;
  return 1;
}
EOF
  $MYCC $MYCFLAGS -c conftest-$$.c # set -e cares for errors.
  $MYLD $MYLDFLAGS -o conftest-$$ conftest-$$.o # dito.
  if ./conftest-$$ ; then
    echo '#define LARGE_FILE_SUPPORT "FOB-INTERFACE" /* systype-info */' \
      >auto-systype.lfs
    rm -f conftest-$$ conftest-$$.*
    LFS_CFLAGS="-D_LARGEFILE_SOURCE -D_FILE_OFFSET_BITS=64"
    return
  fi
  rm -f conftest-$$ conftest-$$.*
  echo "Failed to determine how to get large file support." >&2
  echo "Compiled sources are limited in file size!" >&2
  return
}

LFS_CFLAGS=
lfs

(
cat <<EOF
#! /bin/sh
# automatically generated, do not edit
exec \\
$MYCC \\
$DEFS $INCLUDES \\
$PREMAKE_DEFS \\
$MYCFLAGS $LFS_CFLAGS \\
"\$@"
EOF
) >auto-compile.sh.t
finish_script compile

(
cat <<EOF
#! /bin/sh
# automatically generated, do not edit
exec \\
$MYCC \\
$DEFS $INCLUDES \\
$PREMAKE_DEFS \\
$MYCFLAGSW $LFS_CFLAGS \\
"\$@"
EOF
) >auto-compilew.sh.t
finish_script compilew

(
cat <<EOF
exec \\
$MYLD \\
$MYLDFLAGS \\
-o "\$@" $MYLIBS
EOF
) >auto-link.sh.t
finish_script link

(
cat <<EOF
# automatically generated, do not edit
$MYAR cru "\$@" 
exec $MYRANLIB "\$1"
EOF
) >auto-makelib.sh.t
finish_script makelib
