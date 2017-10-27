# Description

A folder structure and a set of bash scripts to help with self-signed certificates creation. Scripts use the `openssl` tool.

## Structure

- `bin` Executable scripts to create certificates.
- `certs` It's where all the certificates go after creation.
- `confs` Configuration files that is used during the creation. Common names, emails and so on can be adjusted here.
- `private` CA private key folder.
- `reqs` Files of certificate requests to CA
- `signedcerts` It'swhere all the signed certificates go.

## Step-by-step

- Init the configuration with `$ ./bin/init.sh`. The script sets the current folder in the `ca.cnf` file.
- Create a CA certificate with `$ ./bin/create-ca-cert.sh`. It creates the certificate in the `certs` folder and the private key for it in the `private` folder. The script uses the `ca.cnf` configuration. During the execution, you will be asked for a passphrase to protect your CA private key (2 times).
- Create a server certificate with `$ ./bin/create-server-cert.sh "server"`. It creates the certificate in the `certs` folder and signs it with the CA key. Also, it creates the key of the certificate in the `private` folder. During the execution, you will be asked for 
  - a passphrase to protect your server certificate key (3 times)
  - the passphrase of your CA private key (1 time)

Now you have a self-signed certificate that can be used to setup an SSL for your web site. The site can be opened in Chrome without issues.

## Also

You can convert the certificate and the key files into `pfx` format that is a container for a certificate and the private key of this certificate. Just run the command 

```
$ ./bin/convert_pem_to_pfx.sh server "Arbitrary description of the certificate"
```
You will be asked for the server certificate passphrase twice. The `pfx` file goes to the `certs` folder.

## Links

- [HOWTO: Create Your Own Self-Signed Certificate with Subject Alternative Names Using OpenSSL in Ubuntu Bash for Window](https://gist.github.com/jchandra74/36d5f8d0e11960dd8f80260801109ab0)
- [Fixing Chrome 58+ [missing_subjectAltName] with openssl when using self signed certificates](https://alexanderzeitler.com/articles/Fixing-Chrome-missing_subjectAltName-selfsigned-cert-openssl/)
