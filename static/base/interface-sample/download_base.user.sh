#!/bin/bash
USER="dummy_admin"
PASS="xxxxxx"
HOST="w8n00378.bmbg01.telekom.de"
PROT="http"
CONF="w5base2"
MODULE="base::user"
FIELDS="fullname,surname,givenname"

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
