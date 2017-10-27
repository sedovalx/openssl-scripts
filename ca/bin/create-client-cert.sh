#!/usr/bin/env bash

cert_name=$1
export OPENSSL_CONF=confs/client.cnf

# generate the certificate and key
openssl req -newkey rsa:2048 -keyout private/${cert_name}_temp_key.pem -keyform PEM -out reqs/${cert_name}_temp_req.pem -outform PEM

# create the unencrypted key file
echo "You are about to be asked to re-enter the pass phrase above"
openssl rsa < private/${cert_name}_temp_key.pem > private/${cert_name}_key.pem

export OPENSSL_CONF=confs/ca.cnf

# sign the server certificate
openssl ca -in reqs/${cert_name}_temp_req.pem -out certs/${cert_name}_crt.pem

echo "$cert_name certificate is created: certs/${cert_name}_crt.pem, private/${cert_name}_key.pem"