#!/usr/bin/env bash

mkdir certs
mkdir private
mkdir reqs
mkdir signedcerts

current_dir=$(pwd)
sed -i -e "s+#root_folder#+$current_dir+g" confs/ca.cnf
rm confs/ca.cnf-e

echo "Done. The confs/ca.cnf is updated."