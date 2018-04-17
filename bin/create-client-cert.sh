#!/usr/bin/env bash

BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo_clr() {
    echo -e "${BLUE}$1${NC}"
}

read -r -d '' MESSAGE << EOM
The command supports next arguments:
 - *required* a name of a user (example: alexander.sedov)
 - *optional* start date of the certificate in the format of YYMMDDHHMMSSZ (example: 20180412235500Z)
 - *optional* end date of the certificate in the format of YYMMDDHHMMSSZ (example: 20180412235500Z)
EOM
MESSAGE="The command supports a next parameters *required* parameter - a name of a user (example: alexander.sedov)"

: ${1?$MESSAGE}
if [ -z "$1" ]; then
	echo "$MESSAGE"
	exit 1
fi

# Replace all spaces with underscores
USER_NAME=${1// /_}
START_DATE=$2
END_DATE=$3

echo_clr "Creation of the $USER_NAME key..."
# openssl -aes256 genrsa -out private/$USER_NAME.key.pem 2048
openssl genrsa -out private/$USER_NAME.key.pem 2048

# chmod 400 private/$USER_NAME.key.pem

echo_clr "Creation of the $USER_NAME certificate request..."
openssl req -config openssl.cnf \
    -new -sha256 \
    -key private/$USER_NAME.key.pem \
    -out csr/$USER_NAME.csr.pem

echo_clr "Creation of the $USER_NAME certificate..."
if ! ([ -z "$START_DATE" ] || [ -z "$END_DATE" ])    
then
    openssl ca \
        -config openssl.cnf \
        -extensions usr_cert \
        -startdate $START_DATE \
        -enddate $END_DATE \
        -notext \
        -md sha256 \
        -in csr/$USER_NAME.csr.pem \
        -out certs/$USER_NAME.cert.pem
else
    openssl ca \
        -config openssl.cnf \
        -extensions usr_cert \
        -days 375 \
        -notext \
        -md sha256 \
        -in csr/$USER_NAME.csr.pem \
        -out certs/$USER_NAME.cert.pem
fi

# chmod 444 certs/$USER_NAME.cert.pem

echo_clr "Verify the certificate..."
openssl verify -CAfile certs/ca-chain.cert.pem certs/$USER_NAME.cert.pem

# Show the certificate
openssl x509 -noout -text -in certs/$USER_NAME.cert.pem    