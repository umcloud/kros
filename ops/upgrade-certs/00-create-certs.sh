#!/bin/bash
set -ue
CERTDIR=/etc/kubernetes/ssl
BACKDIR=${CERTDIR}/bak-$(date +%F)
mkdir -p ${BACKDIR}
for cert in apiserver apiserver-kubelet-client front-proxy-client; do
    (set -xu
    cp -pbv ${CERTDIR}/${cert}.{key,crt} ${BACKDIR}
    kubeadm alpha certs renew ${cert} --cert-dir $CERTDIR
    )
done
