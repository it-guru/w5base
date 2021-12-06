#!/bin/bash
export OPENSSL_CONF=$(mktemp)
cat << EOF > $OPENSSL_CONF
[req]
prompt = no
distinguished_name = CERT

[CERT]
C = DE
L = Bamberg
ST = Bavaria
O = Deutsche Telekom IT GmbH
OU = Org Unit Name
CN = world.in.baunach.central.de
emailAddress = it@guru.de
EOF
openssl req -newkey rsa:3072 -keyout serverPrivate.key \
            -nodes -out ServerCSR.pem
rm -f $OPENSSL_CONF 2>/dev/null
