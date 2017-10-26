#!/usr/bin/env bash

cert_name=$1
desc=$2
cat private/${cert_name}_key.pem certs/${cert_name}_crt.pem > hold.pem
openssl pkcs12 -export -out certs/$cert_name.pfx -in hold.pem -name "$desc"
rm hold.pem