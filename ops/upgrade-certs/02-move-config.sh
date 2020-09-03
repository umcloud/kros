mv -b admin.conf /etc/kubernetes/
mv -b controller-manager.conf /etc/kubernetes/
mv -b kubelet.conf /etc/kubernetes/
mv -b scheduler.conf /etc/kubernetes/
# Brutally force containers restart
pkill -e kube-apiserver
pkill -e kube-controller-manager
pkill -e kube-scheduler
