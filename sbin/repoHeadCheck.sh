#!/bin/sh
CHKWF=""
ALLOTHERS=""
if echo "$1" | egrep -q 'https://'; then
   CHKWF=$1
   shift 
fi
L="$*"

if [ ! -d .svn -a ! -z "$W5BASEINSTDIR"  -a -d "$W5BASEINSTDIR" ]; then
   echo "change to $W5BASEINSTDIR"
   cd $W5BASEINSTDIR
fi
BASE=$(svn info .| egrep '^URL:' | awk '{print $2}');
HAVECOLISTIONS=0
OKFILES="";

for f in $L; do 
   CREV=""
   BADFILE=0
   if [ -f $f ]; then
      CREV=$(svn info $f | egrep 'Revision:' | awk '{print $2}')
   fi
   if [ "$CREV" = "" ]; then
      WF=$(svn log $BASE/$f 2>/dev/null | \
         sed -e "s#\(https://..*\?/.*/.*\?/workflow/ById/[0-9]\+\)#\n\1\n#g"|\
         egrep '^https://.*auth' | sort | uniq)
      if [ -z "$WF" ]; then
         /bin/echo -e "ERROR: file $f have not any Workflow logs\n" >&2
         BADFILE=1
      fi
   else
      WF=$(svn log -r $CREV:HEAD $f | \
         sed -e "s#\(https://..*\?/.*/.*\?/workflow/ById/[0-9]\+\)#\n\1\n#g"|\
         egrep '^https://.*auth' | sort | uniq)
   fi
   ALLOTHERS="$ALLOTHERS\n$WF\n" 
   if [ ! -z "$CHKWF" ]; then
      OTHERWF=$(echo "$WF" | grep -v "^$CHKWF")
      if [ ! -z "$OTHERWF" ]; then
         /bin/echo -e "WARN:  workflow colision in $f\n       $OTHERWF\n" >&2
         HAVECOLISTIONS=1
      else
         if [ "$BADFILE" != "1" ]; then
            OKFILES="$OKFILES $f"
         fi
      fi
   fi
done
ALLOTHERS=$(/bin/echo -e "$ALLOTHERS" | sort | uniq)
if [ -z "$CHKWF" ]; then
   if [ ! -z "$ALLOTHERS" ]; then
      echo "All related outstanding workflows:"
      /bin/echo -e "$ALLOTHERS" 
      echo ""
   fi
   exit 0
else 
   if [ "$HAVECOLISTIONS" = "1" -a ! -z "$OKFILES" ]; then
      echo "Files with no colisions:"
      echo -e "$OKFILES" 
      echo ""

   fi
fi
if [ "$HAVECOLISTIONS" = "1" ]; then
   exit 1    # Einspielung ist NICHT OK
fi
exit 0       # Einspielung ist OK


