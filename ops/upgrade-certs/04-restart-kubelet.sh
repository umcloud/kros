#export KUBECONFIG=/etc/kubernetes/admin.conf
# Drain
#kubectl drain --ignore-daemonsets $(hostname)
# Stop kubelet
sudo systemctl stop kubelet
# Delete files
sudo rm /var/lib/kubelet/pki/*
# Copy file
sudo mv kubelet.conf /etc/kubernetes/
# Restart
sudo systemctl start kubelet
# Uncordon
#kubectl uncordon $(hostname)

# Check kubelet
echo -n | openssl s_client -connect $(hostname):10250 2>&1 | sed -ne '/-BEGIN CERTIFICATE-/,/-END CERTIFICATE-/p' | openssl x509 -text -noout | grep Not
