# Generate kubelet.conf
set -ue
CERTDIR=/etc/kubernetes/ssl
kubeadm alpha kubeconfig --cert-dir ${CERTDIR} user --org system:nodes --client-name system:node:$(hostname) > kubelet.conf
chown root:root kubelet.conf
chmod 600 kubelet.conf
