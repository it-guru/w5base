#!/bin/bash
USER="service_inetwork"
PASS="xxxxxxxx"
HOST="darwin.telekom.de"
PROT="https"
CONF="darwin"
MODULE="TCOM::custappl"
FIELDS="name,sem,tsm,sememail,tsmemail"

unset HTTP_PROXY
unset http_proxy

qmodule="`echo $MODULE | sed -e 's/::/\//g'`"

URL="$PROT://$HOST/$CONF/auth/$qmodule/Result?UseLimit=0&FormatAs=XMLV01"
URL="$URL&CurrentView=($FIELDS)"
echo "URL=$URL"
wget --http-user=$USER \
     --header="Accept-Language: en" \
     --http-passwd=$PASS \
     -O test-result.xml \
     $URL
