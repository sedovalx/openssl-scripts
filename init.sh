#!/usr/bin/env bash

BLUE='\033[0;34m'
NC='\033[0m' # No Color

read -r -d '' MESSAGE << EOM
The command supports next arguments:
 - *required* the name of the target folder where the CA should be created (the name is added to the current dir)
 - *optional* names of the intermediate certificates, comma separated
EOM

: ${1?"$MESSAGE"}
if [ -z "$1" ]; then
	echo "$MESSAGE"
	exit 1
fi

CA_DIR=$PWD/$1
PARAMS=("$@")
INTERM_DIR_NAMES=("${PARAMS[@]:1}")
PATHLEN=0

INTERM_DIRS=()

for name in "${INTERM_DIR_NAMES[@]}"
do
	PARTS=(${name//\// })
	if [ ${#PARTS[@]} -gt $PATHLEN ]
	then
		PATHLEN=${#PARTS[@]}
	fi

	if [ ${#PARTS[@]} -gt 1 ]
	then
		TEMP=$CA_DIR
		for part in "${PARTS[@]}"
		do 
			TEMP="$TEMP/$part"
			INTERM_DIRS+=("$TEMP")
		done
		unset TEMP
	else 
		INTERM_DIRS+=("$CA_DIR/$name")
	fi
done

unset INTERM_DIR_NAMES

echo -e "The next folder structure is about to be created."
echo -e "${BLUE}The root CA folder:${NC}"
echo $CA_DIR
echo -e "${BLUE}The intermediate certificate folders:${NC}"
for name in "${INTERM_DIRS[@]}"
do
	echo $name
done
echo -e "${BLUE}Calculated certificate path length (number of intermediate authorities):${NC} $PATHLEN"

mkdir "$CA_DIR"
cd "$CA_DIR"
mkdir certs crl newcerts private
#chmod 700 private
touch index.txt
echo 1000 > serial

echo "[ca]
default_ca = CA_default

[ CA_default ]
# Directory and file locations.
dir               = $CA_DIR
certs             = $dir/certs
crl_dir           = $dir/crl
new_certs_dir     = $dir/newcerts
database          = $dir/index.txt
serial            = $dir/serial
RANDFILE          = $dir/private/.rand

# The root key and root certificate.
private_key       = $dir/private/ca.key.pem
certificate       = $dir/certs/ca.cert.pem

# For certificate revocation lists.
crlnumber         = $dir/crlnumber
crl               = $dir/crl/ca.crl.pem
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
emailAddress            = optional

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
countryName_default             = GB
stateOrProvinceName_default     = England
localityName_default            =
0.organizationName_default      = Alice Ltd
organizationalUnitName_default  =
emailAddress_default            =

[ v3_ca ]
subjectKeyIdentifier = hash
authorityKeyIdentifier = keyid:always,issuer
basicConstraints = critical, CA:true
keyUsage = critical, digitalSignature, cRLSign, keyCertSign

[ v3_intermediate_ca ]
subjectKeyIdentifier = hash
authorityKeyIdentifier = keyid:always,issuer
basicConstraints = critical, CA:true, pathlen:$PATHLEN
keyUsage = critical, digitalSignature, cRLSign, keyCertSign

[ crl_ext ]
authorityKeyIdentifier=keyid:always

[ ocsp ]
basicConstraints = CA:FALSE
subjectKeyIdentifier = hash
authorityKeyIdentifier = keyid,issuer
keyUsage = critical, digitalSignature
extendedKeyUsage = critical, OCSPSigning
" > openssl.cnf

echo -e "${BLUE}Creating the root key...${NC}"
openssl genrsa -aes256 -out private/ca.key.pem 4096
chmod 400 private/ca.key.pem

echo -e "${BLUE}Creating the root certificate...${NC}"
openssl req -config openssl.cnf \
	-key private/ca.key.pem \
	-new -x509 -days 7300 -sha256 -extensions v3_ca \
	-out certs/ca.cert.pem

# Read-only for everyone
chmod 444 carts/ca.cert.pem

# Show the generated certificate
openssl x509 -noout -text -in certs/ca.cert.pem

# Create the certificate chain file
cat certs/ca.cert.pem > certs/ca-chain.cert.pem

for folder in "${INTERM_DIRS[@]}"
do
	INTERM_NAME="${folder##*/}"
	echo -e "${BLUE}Creation of the ${NC}$INTERM_NAME${BLUE} intermediate certificate${NC}"

	mkdir "$folder"
	cd "$folder"
	mkdir certs crl csr newcerts private
	#chmod 700 private
	touch index.txt
	echo 1000 > serial
	echo 1000 > crlnumber

	echo "[ca]
	default_ca = CA_default

	[ CA_default ]
	# Directory and file locations.
	dir               = $folder
	certs             = $dir/certs
	crl_dir           = $dir/crl
	new_certs_dir     = $dir/newcerts
	database          = $dir/index.txt
	serial            = $dir/serial
	RANDFILE          = $dir/private/.rand

	# The root key and root certificate.
	private_key       = $dir/private/$INTERM_NAME.key.pem
	certificate       = $dir/certs/$INTERM_NAME.cert.pem

	# For certificate revocation lists.
	crlnumber         = $dir/crlnumber
	crl               = $dir/crl/$INTERM_NAME.crl.pem
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
	emailAddress            = optional

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
	countryName_default             = GB
	stateOrProvinceName_default     = England
	localityName_default            =
	0.organizationName_default      = Alice Ltd
	organizationalUnitName_default  =
	emailAddress_default            =

	[ v3_ca ]
	subjectKeyIdentifier = hash
	authorityKeyIdentifier = keyid:always,issuer
	basicConstraints = critical, CA:true
	keyUsage = critical, digitalSignature, cRLSign, keyCertSign

	[ v3_intermediate_ca ]
	subjectKeyIdentifier = hash
	authorityKeyIdentifier = keyid:always,issuer
	basicConstraints = critical, CA:true, pathlen:$pathlen
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

done

