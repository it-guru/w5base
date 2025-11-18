#!/bin/bash
set -x
rm -f certs/tls-ca-bundle.pem 2>/dev/null
cp /etc/pki/ca-trust/extracted/pem/tls-ca-bundle.pem certs/tls-ca-bundle.pem
chmod 654 certs/tls-ca-bundle.pem

rm -f certs/apache-selfsigned.key 2>/dev/null
rm -f certs/apache-selfsigned.crt 2>/dev/null

openssl req -config ./certs/selfsigned.cnf -x509 -nodes -days 3650 -newkey rsa:1024 -keyout certs/apache-selfsigned.key -out certs/apache-selfsigned.crt



