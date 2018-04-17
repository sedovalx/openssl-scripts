#!/usr/bin/env bash

MESSAGE="The command supports a single *required* parameter - a file name of a certificate without an extension (example: alexander.sedov)"

: ${1?$MESSAGE}
if [ -z "$1" ]; then
	echo "$MESSAGE"
	exit 1
fi

CERT_NAME=$1

cat private/${CERT_NAME}.key.pem certs/${CERT_NAME}.cert.pem > hold.pem 
# openssl pkcs12 -export -out pfx/$CERT_NAME.pfx -in hold.pem -name "$CERT_NAME" 
openssl pkcs12 -export \
    -in certs/${CERT_NAME}.cert.pem \
    -inkey private/${CERT_NAME}.key.pem \
    -name "$CERT_NAME" \
    -out pfx/$CERT_NAME.pfx \
    -certfile certs/ca-chain.cert.pem
rm hold.pem
