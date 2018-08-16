#!/bin/bash

#
# Imports certificate chains into the VM. This script is a Vagrant provisioner that requires sudo access. All chains
# with file names ending with '.pem' or '.crt' inside /vagrant will be added to the system level OpenSSL trust store.
#

CA_TRUST_DIR=/etc/pki/ca-trust/source/anchors

find /vagrant/ \
     \( -path '/vagrant/environments/*' \
     -o -path '/vagrant/.*/*' \) \
     -prune -o \
     \( -iname '*.crt' -o -iname '*.pem' -o -iname '*.cer' \) \
     -a -type f \
     -print | \
     xargs -L 1 grep -l "BEGIN CERTIFICATE" | \
     while read CERTS; do

  cp -u "${CERTS}" "${CA_TRUST_DIR}"

done

/usr/bin/update-ca-trust
