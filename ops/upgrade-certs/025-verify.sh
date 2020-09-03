#!/bin/bash
set -u
# Cert from api-server
echo "api-server"
echo -n | openssl s_client -connect $1:6443 2>&1 | sed -ne '/-BEGIN CERTIFICATE-/,/-END CERTIFICATE-/p' | openssl x509 -text -noout | grep Not
# Cert from controller manager
echo "controller-manager"
echo -n | openssl s_client -connect $1:10257 2>&1 | sed -ne '/-BEGIN CERTIFICATE-/,/-END CERTIFICATE-/p' | openssl x509 -text -noout | grep Not
# Cert from scheduler
echo "scheduler"
echo -n | openssl s_client -connect $1:10251 2>&1 | sed -ne '/-BEGIN CERTIFICATE-/,/-END CERTIFICATE-/p' | openssl x509 -text -noout | grep Not
