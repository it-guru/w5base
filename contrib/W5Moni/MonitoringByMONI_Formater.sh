#!/usr/bin/bash

# .netrc erzeugen mit ...
# |
# | machine w5base-testenv.telekom.de
# | login service/xxxxxx
# | password xxxxxxxxxxxx
# |
#
# ... und auf die dann chmod 600 !
#

W5HOST="w5base-testenv.telekom.de"
W5CONF="darwin"
DATAOBJ="tsdina::system"
MONQUERY="search_name=qde8hv&CurrentView=(name)"

# Der MONI Foramter setzt vorraus, dass mit search_xxx ein
# Datensatz gesucht wird und exakt das was in der Suche gesucht
# wird, auch in EINEM Ergebnis-Datensatz zurück geliefert
# wird. Aus diesem Grund muss auch das Suchfeld in CurrentView
# angeben werden.
# Ist dies der Fall, so wird ein HTTP-Code=200 erzeugt. Alle 
# anderen Zustände erzeugen einen HTTP-Code ungleich 200.
# 

doCheck(){
   INTERF="$1"
   DATAOBJ="$2"
   MONQUERY="$3"
   TSTAMP=$(TZ=UTC date +'%Y%d%m %H:%M:%S')
   Q="https://${W5HOST}/${W5CONF}/auth/${DATAOBJ//::/\\/}/Result?${MONQUERY}"
   HCODE=`curl -n -s -o /dev/null -w "%{http_code}\n" $Q ` 

   WARN=""
   if [ "$HCODE" != "200" ]; then
      WARN="!!!"
      echo -ne '\007'
   fi

   printf "%-18s  -  %-12s %-20s = %s%s\n" \
          "$TSTAMP UTC" ${INTERF} ${DATAOBJ} $HCODE $WARN
}


declare -a TESTLIST
if [ "$1" != "" ]; then
   echo "Reading $1"
   readarray TESTLIST < $1

   while true; do 
      for index in "${!TESTLIST[@]}"; do 
         set -- ${TESTLIST[$index]}
         I="$1" D="$2" Q="$3"
         doCheck "$I" "$D" "$Q"
         sleep 1
      done
      sleep 10
   done
else
  doCheck "Test" "$DATAOBJ" "$MONQUERY"
fi



exit 0

