# OpenSSL CA scripts

## Description

The repository is a set of scripts to automate creation of a CA on a base of the OpenSSL tool. It supports:

- Creation of a CA
- Creation of intermediate cetificates
- Creation of server certificates that conform Google Chrome requirements
- Creation of client certificates
- (TODO) Revokation lists

All of this was possible because of [the great article of Jamie Nguyen](https://jamielinux.com/docs/openssl-certificate-authority) and couple of other internet sources.

The scripts are mostly intended to be used for generation of test certificates. If you plan to use it in production please read the article first and examine the sources. At very least you'll probably want to uncomment several `chmod` directives which protect key and certificate files.

## Usage

## Folder stricture

Each of the commands that generate either a CA certificate or an intermediate certificate create the next folder structure:

- `bin` the folder where the scripts goes
- `certs` contains PEM files with certificate data
- `private` contains corresponding PEM files with key data
- `csr` contains certificate requests PEM files
- `crl` contains revocation lists files (TODO)
- `openssl.cnf` is a configuration file that is used during the certificate creation on this level
- `index.txt`, `serial`, `crlnumber` are internals that keep the state

### Creation of the CA certificate

In the root of the repository run the next command

```bash
$ ./init-ca.sh root-ca
Creating the root key...
Generating RSA private key, 4096 bit long modulus
................................................................................................................................................................................................++
......................................................++
e is 63437 (0x10001)
```

Then you need to enter and repeet a pass phrase to protect your CA key. It may be an arbitrary sequence of symbols. You need to remember it!

```bash
Enter pass phrase for private/ca.key.pem:
Verifying - Enter pass phrase for private/ca.key.pem:
```

The next step is the creation of the root certificate itself. You need to endter the pass phrase of your CA key to proceed. Make sure to specify the common name and the email address fields.

```bash
Creating the root certificate...
Enter pass phrase for private/ca.key.pem:
You are about to be asked to enter information that will be incorporated
into your certificate request.
What you are about to enter is what is called a Distinguished Name or a DN.
There are quite a few fields but you can leave some blank
For some fields there will be a default value,
If you enter '.', the field will be left blank.
-----
Country Name (2 letter code) [DE]:
State or Province Name [Germany]:
Locality Name []:
Organization Name [Acme Test]:
Organizational Unit Name []:CA
Common Name []:Acme Test CA
Email Address []:admin@acme.com
```

Now you have a self-signed CA certificate.

### Creation of an intermediate certificate

In this example, we will create two intermediate certificates. During the creation of an intermediate certificate you need to specify how many of nested intermediates do you allow. So for the first intermediate certificate we specify `1` as one more nested intermediate certificate is allowed.

```bash
# Move to the generated folder of the CA first
$ cd root-ca
$ ./bin/init-interm.sh interm-adm 1
Creating the interm-adm key...
Generating RSA private key, 4096 bit long modulus
..........................................++
..........................++
e is 65537 (0x10001)
```

Then you need to enter and repeet a pass phrase to protect your **intermediate** certificate's key.

```bash
Enter pass phrase for private/interm-adm.key.pem:
Verifying - Enter pass phrase for private/interm-adm.key.pem:
```

Reenter the pass phrase for your intermediate certificate's key to allow `openssl` to create the certificate request. Make sure to specify the common name and the email address fields. Also, in case of the intermediate certificates creation the scripts uses a strict policy that requre an intermediate certificate has the same values for `Country Name`, `State or Province Name` and `Organization Name` fields as in the CA certificate.

```bash
Creating the interm-adm certificate request...
Enter pass phrase for private/interm-adm.key.pem:
You are about to be asked to enter information that will be incorporated
into your certificate request.
What you are about to enter is what is called a Distinguished Name or a DN.
There are quite a few fields but you can leave some blank
For some fields there will be a default value,
If you enter '.', the field will be left blank.
-----
Country Name (2 letter code) [DE]:
State or Province Name [Germany]:
Locality Name []:
Organization Name [Acme Test]:
Organizational Unit Name []:Adm
Common Name []:Acme Test interm Adm
Email Address []:admin@acme.com
```

The next thing is signing the intermediate certificate with the CA's key. So you will be asked to enter the **CA key**'s pass phrase.

```bash
Creating the interm-adm certificate...
Using configuration from /dev/fd/63
Enter pass phrase for /path/to/root-ca/private/ca.key.pem:
Check that the request matches the signature
Signature ok
```

After that, you need to confirm twice and here it is - your intermediate certificate is ready and can be found in the `root-ca/interm-adm/certs` folder. It is issued and signed by the previously created CA certificate.

The creation of a nested intermediate certificate is straightforward. You need to go on the level of the `interm-adm` (parent) certificate and execute the same commands as for the creation of the first intermediate certificate.

```bash
cd root-ca/interm-adm
./bin/init-interm.sh interm-hub
```

It is an edge level intermediate certificate so the number of allowed nested intermediates is zero. It is a default value so you don't need to specify it as an argument. All other things are the same

- Enter and repeat a pass phrase to protect the key of the new certificate
- Enter it again to create a certificate request
- Specify certificate's DN details. Don't forget to use the same values for `Country Name`, `State or Province Name` and `Organization Name` fields as in the CA certificate. Fields `Common Name` and `Email Address` are required.
- Enter the pass phrase of the **parent** intermediate certificate (it is `interm-adm` in our case) to sign the new certificate

That's it, the new intermediate certificate is ready. It is issued and signed by the parent intermediate certificate.

## Creation of a server certificate



## Troubleshooting

- Check if the `openssl` is installed in your system and is in the PATH
- Try to go through the process using the same pass phrase for all (Ca and intermediates) keys. Then, if everything goes fine, try to start from the begining using different pass phrases.
- Don't forget to `cd` before executing the `init-interm.sh` script
- Plan the certificate path length from the begining. Basically, when you create a top level intermediate certificate you need to know how many nested intermediates you want to create.