#!/usr/bin/env bash

BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo_clr() {
    echo -e "${BLUE}$1${NC}"
}

read -r -d '' MESSAGE << EOM
The command supports next arguments:
 - *required* the name of the target folder where the intermediate CA should be created (the name is added to the current dir)
 - *optional* max lenght of a certificate path that can be created with this intermediate certificate (default: 0)
EOM

: ${1?"$MESSAGE"}
if [ -z "$1" ]; then
	echo "$MESSAGE"
	exit 1
fi

TARGET_DIR=$PWD/$1
NAME=$1
PATHLEN=${2:-0}

mkdir $TARGET_DIR
cd $TARGET_DIR
mkdir certs crl csr newcerts pfx private
# chmod 700 private
touch index.txt
echo 1000 > serial
echo 1000 > crlnumber

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
private_key       = \$dir/private/$NAME.key.pem
certificate       = \$dir/certs/$NAME.cert.pem

# For certificate revocation lists.
crlnumber         = \$dir/crlnumber
crl               = \$dir/crl/$NAME.crl.pem
crl_extensions    = crl_ext
default_crl_days  = 30

# SHA-1 is deprecated, so use SHA-2 instead.
default_md        = sha256

name_opt          = ca_default
cert_opt          = ca_default
default_days      = 375
preserve          = no
policy            = policy_loose

[ policy_loose ]
# Allow the intermediate CA to sign a more diverse range of certificates.
countryName             = optional
stateOrProvinceName     = optional
localityName            = optional
organizationName        = optional
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

[ crl_ext ]
authorityKeyIdentifier=keyid:always

[ ocsp ]
basicConstraints = CA:FALSE
subjectKeyIdentifier = hash
authorityKeyIdentifier = keyid,issuer
keyUsage = critical, digitalSignature
extendedKeyUsage = critical, OCSPSigning
" > openssl.cnf

echo_clr "Creating the $NAME key..."
openssl genrsa -aes256 -out private/$NAME.key.pem 4096

echo_clr "Creating the $NAME certificate request..."
openssl req -config openssl.cnf -new -sha256 \
	-key private/$NAME.key.pem \
	-out csr/$NAME.csr.pem

echo_clr "Creating the $NAME certificate..."
cd ..
V3_INTERM_CA="
[ v3_intermediate_ca ]
subjectKeyIdentifier = hash
authorityKeyIdentifier = keyid:always,issuer
basicConstraints = critical, CA:true, pathlen:$PATHLEN
keyUsage = critical, digitalSignature, cRLSign, keyCertSign
"	
openssl ca \
	-config <(cat openssl.cnf <(printf "\n$V3_INTERM_CA")) \
	-extensions v3_intermediate_ca \
	-days 3650 -notext -md sha256 \
	-in $NAME/csr/$NAME.csr.pem \
	-out $NAME/certs/$NAME.cert.pem	

cd $NAME	

# Read-only for everyone
# chmod 444 $NAME/certs/$NAME.cert.pem


echo_clr "Verify the certificate..."
openssl verify -CAfile ../certs/ca-chain.cert.pem certs/$NAME.cert.pem

# Show the certificate
openssl x509 -noout -text -in certs/$NAME.cert.pem

# Create the certificate chain file
cat certs/$NAME.cert.pem ../certs/ca-chain.cert.pem > certs/ca-chain.cert.pem	