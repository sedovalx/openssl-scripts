#!/usr/bin/env bash

export OPENSSL_CONF=confs/ca.cnf
openssl req -x509 -newkey rsa:2048 -out certs/ca_crt.pem -outform PEM -days 1825

echo "CA certificate is created: certs/ca_crt.pem, private/ca_key.pem"