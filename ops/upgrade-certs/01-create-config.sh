#!/bin/bash
set -ue
CERTDIR=/etc/kubernetes/ssl
kubeadm alpha kubeconfig user --org system:masters --client-name kubernetes-admin --cert-dir ${CERTDIR} > admin.conf 
kubeadm alpha kubeconfig user --client-name system:kube-controller-manager --cert-dir ${CERTDIR} > controller-manager.conf
kubeadm alpha kubeconfig user --org system:nodes --client-name system:node:$(hostname) --cert-dir ${CERTDIR} > kubelet.conf
kubeadm alpha kubeconfig user --client-name system:kube-scheduler --cert-dir ${CERTDIR} > scheduler.conf

chown root:root {admin,controller-manager,kubelet,scheduler}.conf
chmod 600 {admin,controller-manager,kubelet,scheduler}.conf
