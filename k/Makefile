INVENTORY_DIR=$(CURDIR)/configs/inventory/cluster
help:
	@echo "make init"
	@echo "make nodes-[create|destroy]"
	@echo "make cluster"

include ../Makefile.common

init: packages

packages:
	sudo apt-get install -y git python3-venv
	# Skip if repo already cloned
	test -d $(REPO_DIR)/kubespray || git clone https://github.com/kubernetes-incubator/kubespray.git $(REPO_DIR)/kubespray
	# ruamel.yaml is needed in the pip env for inventory.py later
	pyvenv .venv && source .venv/bin/activate && pip3 install --upgrade pip && pip3 install -r $(REPO_DIR)/kubespray/requirements.txt && pip3 install ruamel.yaml

inventory-prep:
	mkdir -p $(INVENTORY_DIR)
	cp -r $(REPO_DIR)/kubespray/inventory/sample/* $(INVENTORY_DIR)
	sed -i "s/--graph={{ docker_daemon_graph }} {{ docker_log_opts }}/--graph={{ docker_daemon_graph }} {{ docker_log_opts }} --ipv6 --fixed-cidr-v6=fdff::0\/64/g" $(INVENTORY_DIR)/group_vars/all/docker.yml
	sed -i "$$ a\bootstrap_os: ubuntu" $(INVENTORY_DIR)/group_vars/all/all.yml
	sed -i "$$ a\kubeadm_enabled: true" $(INVENTORY_DIR)/group_vars/all/all.yml
	#Fix for -> https://github.com/kubernetes-sigs/kubespray/issues/3314#issuecomment-450473040
	sed -i "$$ a\kubelet_flexvolumes_plugins_dir: /usr/libexec/kubernetes/kubelet-plugins/volume/exec" $(INVENTORY_DIR)/group_vars/all/all.yml
	sed -i "s/#upstream_dns_servers:/upstream_dns_servers:/g" $(INVENTORY_DIR)/group_vars/all/all.yml
	sed -i "s/#  - 8.8.8.8/  - 8.8.8.8/g" $(INVENTORY_DIR)/group_vars/all/all.yml
	sed -i "s/#  - 8.8.4.4/  - 8.8.4.4/g" $(INVENTORY_DIR)/group_vars/all/all.yml
	sed -i "s/helm_enabled: false/helm_enabled: true/g" $(INVENTORY_DIR)/group_vars/k8s-cluster/addons.yml
	sed -i "s/cert_manager_enabled: false/cert_manager_enabled: true/g" $(INVENTORY_DIR)/group_vars/k8s-cluster/addons.yml
	sed -i "s/deploy_netchecker: false/deploy_netchecker: true/g" $(INVENTORY_DIR)/group_vars/k8s-cluster/k8s-cluster.yml

inventory: inventory-prep
	# Fix stupid non-zero prefixed numbers, ie use ${HOST_PREFIX}01 instead of ${HOST_PREFIX}1
	sed -i '/HOST_PREFIX/s/{1}/{1:02}/' $(REPO_DIR)/kubespray/contrib/inventory_builder/inventory.py
	source .venv/bin/activate && cd $(REPO_DIR)/kubespray && \
		declare -a IPS=($(NODES_IPS)) && \
		HOST_PREFIX=$(HOST_PREFIX) CONFIG_FILE=$(INVENTORY_DIR)/hosts.yaml python3 contrib/inventory_builder/inventory.py $${IPS[@]}
	ls -l $(INVENTORY_DIR)/hosts.yaml

cluster: inventory
	source .venv/bin/activate && cd $(REPO_DIR)/kubespray && ansible-playbook -u ubuntu -b -i $(INVENTORY_DIR)/hosts.yaml cluster.yml

kubectl:
	ssh ubuntu@$(MASTER) "sudo cp /etc/kubernetes/admin.conf ~ && sudo chmod 644 admin.conf"
	mkdir -p ~/.kube
	scp ubuntu@$(MASTER):~/admin.conf $$HOME/.kube/config

metallb:
	$(KBCTL) apply -f https://raw.githubusercontent.com/google/metallb/v0.7.3/manifests/metallb.yaml
	$(KBCTL) apply -f $(K8SCONF)metallb-ip-address.yaml

metallb-destroy:
	$(KBCTL) delete -f $(K8SCONF)metallb-ip-address.yaml
	$(KBCTL) delete -f https://raw.githubusercontent.com/google/metallb/v0.7.3/manifests/metallb.yaml

certmanager: metallb
	$(KBCTL) apply -f $(K8SCONF)cluster-issuer.yaml

helm: certmanager
	$(HELM) init
	$(HELM) ls --all

nginx-ingress: helm
	$(KBCTL) apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/master/deploy/mandatory.yaml
	$(KBCTL) apply -f $(K8SCONF)cloud-generic.yaml

nginx-ingress-destroy:
	$(KBCTL) delete -f $(K8SCONF)cloud-generic.yaml
	$(KBCTL) delete -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/master/deploy/mandatory.yaml

openebs:
	$(HELM) install --namespace openebs --name openebs stable/openebs
	$(KBCTL) apply -f https://raw.githubusercontent.com/openebs/openebs/master/k8s/openebs-storageclasses.yaml

K8SCONF=configs/
SHELL:= /bin/bash
KBCTL=kubectl --insecure-skip-tls-verify --kubeconfig ./admin.conf
HELM=KUBECONFIG=./admin.conf helm
