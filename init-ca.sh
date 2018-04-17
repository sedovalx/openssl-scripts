#!/usr/bin/env bash

BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo_clr() {
    echo -e "${BLUE}$1${NC}"
}

MESSAGE="The command supports a single *required* parameter - the name of the target folder where the CA folder structure should be created (the name is added to the current dir)"

: ${1?$MESSAGE}
if [ -z "$1" ]; then
	echo "$MESSAGE"
	exit 1
fi

TARGET_DIR=$PWD/$1

mkdir $TARGET_DIR
cd $TARGET_DIR
mkdir csr certs crl newcerts pfx private
# chmod 700 private
touch index.txt
echo 1000 > serial

cp -r ../bin .

echo "[ ca ]
default_ca = CA_default

[ CA_default ]
# Directory and file locations.
dir               = $TARGET_DIR
certs             = \$dir/certs
crl_dir           = \$dir/crl
new_certs_dir     = \$dir/newcerts
database          = \$dir/index.txt
serial            = \$dir/serial
RANDFILE          = \$dir/private/.rand

# The root key and root certificate.
private_key       = \$dir/private/ca.key.pem
certificate       = \$dir/certs/ca.cert.pem

# For certificate revocation lists.
crlnumber         = \$dir/crlnumber
crl               = \$dir/crl/ca.crl.pem
crl_extensions    = crl_ext
default_crl_days  = 30

# SHA-1 is deprecated, so use SHA-2 instead.
default_md        = sha256

name_opt          = ca_default
cert_opt          = ca_default
default_days      = 375
preserve          = no
policy            = policy_strict

[ policy_strict ]
# The root CA should only sign intermediate certificates that match.
countryName             = match
stateOrProvinceName     = match
organizationName        = match
organizationalUnitName  = optional
commonName              = supplied
emailAddress            = supplied

[ req ]
default_bits        = 2048
distinguished_name  = req_distinguished_name
string_mask         = utf8only

# SHA-1 is deprecated, so use SHA-2 instead.
default_md          = sha256

# Extension to add when the -x509 option is used.
x509_extensions     = v3_ca

[ req_distinguished_name ]
# See <https://en.wikipedia.org/wiki/Certificate_signing_request>.
countryName                     = Country Name (2 letter code)
stateOrProvinceName             = State or Province Name
localityName                    = Locality Name
0.organizationName              = Organization Name
organizationalUnitName          = Organizational Unit Name
commonName                      = Common Name
emailAddress                    = Email Address

# Optionally, specify some defaults.
countryName_default             = DE
stateOrProvinceName_default     = Germany
localityName_default            =
0.organizationName_default      = Acme Test
organizationalUnitName_default  =
emailAddress_default            =

[ v3_ca ]
subjectKeyIdentifier = hash
authorityKeyIdentifier = keyid:always,issuer
basicConstraints = critical, CA:true
keyUsage = critical, digitalSignature, cRLSign, keyCertSign

[ usr_cert ]
basicConstraints = CA:FALSE
nsCertType = client, email
nsComment = "OpenSSL Generated Client Certificate"
subjectKeyIdentifier = hash
authorityKeyIdentifier = keyid,issuer
keyUsage = critical, nonRepudiation, digitalSignature, keyEncipherment
extendedKeyUsage = clientAuth, emailProtection

[ server_cert ]
basicConstraints = CA:FALSE
nsCertType = server
nsComment = "OpenSSL Generated Server Certificate"
subjectKeyIdentifier = hash
authorityKeyIdentifier = keyid,issuer:always
keyUsage = critical, digitalSignature, keyEncipherment
extendedKeyUsage = serverAuth

[ crl_ext ]
authorityKeyIdentifier=keyid:always

[ ocsp ]
basicConstraints = CA:FALSE
subjectKeyIdentifier = hash
authorityKeyIdentifier = keyid,issuer
keyUsage = critical, digitalSignature
extendedKeyUsage = critical, OCSPSigning
" > openssl.cnf

echo_clr "Creating the root key..."
openssl genrsa -aes256 -out private/ca.key.pem 4096
# chmod 400 private/ca.key.pem

echo_clr "Creating the root certificate..."
openssl req -config openssl.cnf \
	-key private/ca.key.pem \
	-new -x509 -days 7300 -sha256 -extensions v3_ca \
	-out certs/ca.cert.pem

# Read-only for everyone
# chmod 444 carts/ca.cert.pem

# Show the generated certificate
openssl x509 -noout -text -in certs/ca.cert.pem

# Create the certificate chain file
cat certs/ca.cert.pem > certs/ca-chain.cert.pem
