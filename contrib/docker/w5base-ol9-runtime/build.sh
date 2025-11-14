#!/bin/bash

rm -f tls-ca-bundle.pem 2>/dev/null
cp /etc/pki/ca-trust/extracted/pem/tls-ca-bundle.pem certs/tls-ca-bundle.pem
chmod 654 certs/tls-ca-bundle.pem
docker build --progress=plain -t it9000/w5base-ol9-runtime:beta .

