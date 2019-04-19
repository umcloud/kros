REPO=https://github.com/kubernetes-incubator/kubespray.git
REPO_DIR=$(REPO_ROOT)/kubespray

INVENTORY_DIR=$(CURDIR)/configs/inventory/cluster

help:
	@echo "make init"
	@echo "make inventory"
	@echo "make diff"
	@echo "make cluster"

include ../Makefile.common

init: git-clone packages

packages:
	sudo apt-get install -y git python3-venv
	# ruamel.yaml is needed in the pip env for inventory.py later
	pyvenv .venv && source .venv/bin/activate && pip3 install --upgrade pip && pip3 install -r $(REPO_DIR)/requirements.txt && pip3 install ruamel.yaml

inventory-prep:
	./scripts/10-do-prep.sh $(REPO_DIR) $(INVENTORY_DIR)

inventory: inventory-prep
	# Fix stupid non-zero prefixed numbers, ie use ${HOST_PREFIX}01 instead of ${HOST_PREFIX}1
	sed -i '/HOST_PREFIX/s/{1}/{1:02}/' $(REPO_DIR)/contrib/inventory_builder/inventory.py
	source .venv/bin/activate && cd $(REPO_DIR) && \
		declare -a IPS=($(NODES_IPS)) && \
		HOST_PREFIX=$(HOST_PREFIX) CONFIG_FILE=$(INVENTORY_DIR)/hosts.yaml \
		python3 contrib/inventory_builder/inventory.py $${IPS[@]}
	ls -l $(INVENTORY_DIR)/hosts.yaml

diff:
	git diff configs/

cluster:
	source .venv/bin/activate && cd $(REPO_DIR) && \
		ansible-playbook -u ubuntu -b -i $(INVENTORY_DIR)/hosts.yaml cluster.yml

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

nginx-ingress:
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
KBCTL=kubectl --insecure-skip-tls-verify
HELM=KUBECONFIG=./admin.conf helm
