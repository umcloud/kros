REPO_DIR=${1:?missing REPO_DIR}
INVENTORY_DIR=${2:?missing INVENTORY_DIR}

mkdir -p ${INVENTORY_DIR}
cp -r ${REPO_DIR}/inventory/sample/* ${INVENTORY_DIR}

# Allow docker IPv6
sed -e 's/--graph={{ docker_daemon_graph }} {{ docker_log_opts }}/& --ipv6 --fixed-cidr-v6=fdff::0\/64/' \
    -i ${INVENTORY_DIR}/group_vars/all/docker.yml

# kubelet_flexvolumes_plugins_dir works around
# https://github.com/kubernetes-sigs/kubespray/issues/3314#issuecomment-450473040
sed -e '$ a\bootstrap_os: ubuntu' \
    -e '$ a\kubeadm_enabled: true' \
    -e '$ a\kubelet_flexvolumes_plugins_dir: /usr/libexec/kubernetes/kubelet-plugins/volume/exec' \
    -e '$ a\supplementary_addresses_in_ssl_keys: [api.metal.kube.um.edu.ar]' \
    -e '/^#upstream_dns_servers:/s/^#//' \
    -e '/^#  - 8.8.8.8/s/^#//' \
    -e '/^#  - 8.8.4.4/s/^#//' \
    -i ${INVENTORY_DIR}/group_vars/all/all.yml

sed -e '/helm_enabled: /s/false/true/' \
    -e '/cert_manager_enabled: /s/false/true/' \
    -i ${INVENTORY_DIR}/group_vars/k8s-cluster/addons.yml

sed -e '/deploy_netchecker: /s/false/true/' \
    -e '/cluster_name: /s/cluster.local/metal.kube.um.edu.ar/' \
    -i ${INVENTORY_DIR}/group_vars/k8s-cluster/k8s-cluster.yml
