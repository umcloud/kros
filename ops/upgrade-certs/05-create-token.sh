# With below token, on each non-master node:
# - replace token in /etc/kubernetes/bootstrap-kubelet.conf
# - rm -rf /var/lib/kubelet/pki /etc/kubernetes/kubelet.conf # will be recreated on restart
# - systemctl restart kubelet
kubeadm token create > token
