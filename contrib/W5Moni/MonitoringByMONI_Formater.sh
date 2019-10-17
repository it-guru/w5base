#!/usr/bin/bash

# .netrc erzeugen mit ...
# |
# | machine w5base-testenv.telekom.de
# | login service/w5moni
# | password sgXX_geit193
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

MONQUERY="${MONQUERY}&FormatAs=MONI"
while true; do
  HTTPCODE=`curl -n -s -o /dev/null -w "%{http_code}\n"  \
     "https://${W5HOST}/${W5CONF}/auth/${DATAOBJ//::/\\/}/Result?${MONQUERY}"`
  echo "$(TZ=UTC date +'%Y%d%m %H:%M:%S') ${DATAOBJ} = $HTTPCODE"
  sleep 10
done

