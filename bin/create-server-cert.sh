#!/usr/bin/env bash

BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo_clr() {
    echo -e "${BLUE}$1${NC}"
}

MESSAGE="The command supports a single *required* parameter - a fully qualified domain name (example: myserver.com)"

: ${1?$MESSAGE}
if [ -z "$1" ]; then
	echo "$MESSAGE"
	exit 1
fi

DOMAIN_NAME=$1

echo_clr "Creation of the $DOMAIN_NAME key..."
# openssl -aes256 genrsa -out private/$DOMAIN_NAME.key.pem 2048
openssl genrsa -out private/$DOMAIN_NAME.key.pem 2048

# chmod 400 private/$DOMAIN_NAME.key.pem

echo_clr "Creation of the $DOMAIN_NAME certificate request..."
openssl req \
    -new -sha256 \
    -reqexts SAM \
    -extensions SAM \
    -config <(cat openssl.cnf <(printf "\n[SAM]\nsubjectAltName=DNS:$DOMAIN_NAME")) \
    -key private/$DOMAIN_NAME.key.pem \
    -out csr/$DOMAIN_NAME.csr.pem

echo_clr "Creation of the $DOMAIN_NAME certificate..."    
openssl ca \
    -config openssl.cnf \
    -extensions server_cert \
    -days 375 \
    -notext \
    -md sha256 \
    -in csr/$DOMAIN_NAME.csr.pem \
    -out certs/$DOMAIN_NAME.cert.pem

# chmod 444 certs/$DOMAIN_NAME.cert.pem

echo_clr "Verify the certificate..."
openssl verify -CAfile certs/ca-chain.cert.pem certs/$DOMAIN_NAME.cert.pem

# Show the certificate
openssl x509 -noout -text -in certs/$DOMAIN_NAME.cert.pem    

