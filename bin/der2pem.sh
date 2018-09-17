#!/usr/bin/env bash

MESSAGE="The command supports a single *required* parameter - a file name of a DER-encoded certificate file (*.crt)"

: ${1?$MESSAGE}
if [ -z "$1" ]; then
	echo "$MESSAGE"
	exit 1
fi

CRT_FILE_NAME=$1
FILE_NAME=${CRT_FILE_NAME%.*}
PEM_FILE_NAME=$FILE_NAME.pem

openssl x509 -inform der -in "$CRT_FILE_NAME" -out "$PEM_FILE_NAME"
