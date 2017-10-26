#!/usr/bin/env bash

export OPENSSL_CONF=confs/ca.cnf
openssl req -x509 -newkey rsa:2048 -out certs/cacert.pem -outform PEM -days 1825

echo "CA certificate is created: certs/cacert.pem, private/cakey.pem"