PIP_PKGS=wheel "cmd2<=0.8.7" python-openstackclient python-heatclient
# Helper vars for python venv
SETUP_VENV=pyvenv .venv
USE_VENV=source .venv/bin/activate
TEST_VENV=test -f .venv/bin/activate

# TODO(jjo): get from chart vars, should be svc.umcloud.local
OS_DOMAIN=openstack.svc.cluster.local
KEYSTONE_FQDN=keystone.$(OS_DOMAIN)
KEYSTONE_FQDN_HOSTS=$(KEYSTONE_FQDN) $(shell echo {keystone,cinder,glance,neutron,nova,placement,heat}{,-api}.$(OS_DOMAIN))

# DEPLOY_TYPE can be: developer/common (dev) or multinode (prod)
DEPLOY_TYPE=multinode
#DEPLOY_TYPE=developer/common
# TODO(jjo): adapt ceph stuff to Rook
# NOTE: compute-kit includes: nova, neutron
# F_ck... it REALLY wants its own ingress (!): installs in kube-system *and* openstack NS ("ingress" Pods)
DEPLOY_GREP='mariadb|rabbitmq|ingress|memcached|keystone|glance|cinder|openvswitch|libvirt|compute-kit|heat|ceph-radosgateway'
# @navarrow won't let me go without horizon ...
DEPLOY_SCRIPTS_PATT=$(REPO_ROOT)/openstack-helm/tools/deployment/$(DEPLOY_TYPE)/[0-9]*
DEPLOY_SCRIPTS_EXTRA=$(REPO_ROOT)/openstack-helm/tools/deployment/developer/common/100-horizon.sh
DEPLOY_SCRIPTS=$(shell ls $(DEPLOY_SCRIPTS_PATT) $(DEPLOY_SCRIPTS_EXTRA)|sort -u | egrep $(DEPLOY_GREP))
OSH_PASSWORDS_ENV=/etc/openstack/osh-passwords.env
OPENSTACK_CLOUDS=/etc/openstack/clouds.yaml
CHARTS_VALUES_YAML=/etc/openstack/os-charts-values.yaml
OSH_EXTRA_HELM_ARGS="-f $(CHARTS_VALUES_YAML)"

REPO_OS_ROOT=https://git.openstack.org/openstack

help:
	@echo make init
	@echo make prep
	@echo make creds
	@echo make tests
	@echo make deploy

include ../Makefile.common

all: init prep creds tests deploy

# Steps from https://docs.openstack.org/openstack-helm/latest/install/multinode/kubernetes-and-common-setup.html
init: git-clone-openstack-helm git-clone-openstack-helm-infra install-venv

prep: check-helm-bin helm-serve package-infra-charts package-osh-charts label-kube-nodes
	sudo install -m 0700 -o $$(id -nu) -d /etc/openstack

creds: os-charts-values setup-client

tests: os-test-bad-passwords

deploy: os-deploy

setup-client: $(OPENSTACK_CLOUDS)
os-charts-values: $(CHARTS_VALUES_YAML)

# Modified setup-client to only create /etc/openstack/clouds.yaml,
# 'make all' is run afterwards from other target
$(OPENSTACK_CLOUDS): $(OSH_PASSWORDS_ENV)
	. $(OSH_PASSWORDS_ENV) && sed -e 's|password:.*|password: $${KEYSTONE_ADMIN_PASSWORD}|' \
	    -e "s/-xe/-e/" \
	    -e "/pip /d" \
	    -e "/make.all/d" \
		$(REPO_ROOT)/openstack-helm/tools/deployment/$(DEPLOY_TYPE)/0??-setup-client.sh |\
		envsubst > $(CURDIR)/configs/setup-client.sh
	cd $(REPO_ROOT)/openstack-helm && bash $(CURDIR)/configs/setup-client.sh

# Will use same kubernetes master nodes for openstack-control-plane,
# then all nodes for nova (and needed openvswitch)
label-kube-nodes:
	kubectl label nodes openstack-control-plane=enabled -l node-role.kubernetes.io/master --overwrite
	kubectl label nodes openstack-helm-node-class=primary -l node-role.kubernetes.io/master --overwrite
	kubectl label nodes openstack-compute-node=enabled --all --overwrite
	kubectl label nodes openvswitch=enabled --all --overwrite

hack-etc-hosts:
	$(eval INGRESS_IP=$(shell kubectl get svc -n ingress-nginx ingress-nginx -ojsonpath='{.status.loadBalancer.ingress[0].ip}'))
	@test $(INGRESS_IP) != ""
	egrep $(KEYSTONE_FQDN) /etc/hosts && \
		sudo sed -i.bak '/$(KEYSTONE_FQDN)/s/.*/$(INGRESS_IP) $(KEYSTONE_FQDN_HOSTS)/' /etc/hosts || \
		{ echo $(INGRESS_IP) $(KEYSTONE_FQDN_HOSTS) | sudo tee -a /etc/hosts; }


$(CHARTS_VALUES_YAML): configs/os-charts-values.tmpl.yaml $(OSH_PASSWORDS_ENV) Makefile
	. $(OSH_PASSWORDS_ENV) && envsubst < $(<) > $(@)

$(OSH_PASSWORDS_ENV):
	sed -e '/set -xe/d' -e 's|/tmp/osh-passwords.env|$(OSH_PASSWORDS_ENV)|' $(REPO_ROOT)/openstack-helm/tools/deployment/armada/generate-osh-passwords.sh| bash

# Do the actual deploy by running DEPLOY_SCRIPTS in sequence,
# DEPLOY_SCRIPTS is filtered-in for only the components we want
# to deploy
# Need to void NETWORK_TUNNEL_DEV=<local_default_route_interface> to avoid using this *local*
# iface on cluster nodes (wtf?)
os-deploy:
	@echo "Deploying for DEPLOY_TYPE=$(DEPLOY_TYPE) ..."
	@cd $(REPO_ROOT)/openstack-helm && export OSH_EXTRA_HELM_ARGS=$(OSH_EXTRA_HELM_ARGS) && \
		for i in $(DEPLOY_SCRIPTS); do \
		(echo "=== $$i ==="; sed -r -e '/tunnel:.*NETWORK_TUNNEL_DEV.*/s/tunnel:/tunnel_broken_disabled:/' $$i | env PS4='=== ' bash); \
		done

# Run 'helm template' instead on each chart, to peek
# at the generated YAML output for the deploy
os-template:
	@cd $(REPO_ROOT)/openstack-helm && export OSH_EXTRA_HELM_ARGS=$(OSH_EXTRA_HELM_ARGS) && \
		for i in $(DEPLOY_SCRIPTS); do \
		(sed -r -e '/wait/,$$d' -e 's/helm upgrade --install \S+/helm template/' $$i| env PS4='=== ' bash); \
		done
# Run 'helm inspect' instead on each chart, to peek
# on charts' settings.
# Note: no OSH_EXTRA_HELM_ARGS for inspect, hacky sed to
# remove all the rest of the script from 'wait' to the end,
os-inspect:
	@cd $(REPO_ROOT)/openstack-helm && \
		for i in $(DEPLOY_SCRIPTS); do \
		(sed -r -e '/wait/,$$d' -e '/--namespace|--values|--set|OSH_/d' -e 's/helm upgrade --install \S+ (\S+).*/helm inspect \1/' $$i| env PS4='=== ' bash) 2>&1 ; \
		done

# Test for the use of 'password' (literal) as password,
# fail if found.
# NOTE: Skipping "OS_AUTH_TYPE: ..." from the grep,
# as it can be indeed password type
os-test-bad-passwords:
	@echo 'Showing charts configured with secrets as "password"[sic]'
	$(eval PASSWORD_B64=$(shell echo -n password|base64))
	($(MAKE) os-template | egrep -v OS_AUTH_TYPE: | egrep -B5 '$(PASSWORD_B64)' >&2) 2>&1; [ $$? -ne 0 ]
	($(MAKE) os-template | sed -rn 's/  .+_CONNECTION:.//p'|xargs -I@ sh -c 'echo @|base64 -d;echo' | egrep '$(PASSWORD_B64)' >&2); [ $$? -ne 0 ]
	@echo PASS

# Package all openstack-help-infra charts
package-infra-charts:
	$(MAKE) -C $(REPO_ROOT)/openstack-helm-infra all

# Verify whem in path, newer openstack-helm charts need v2.13+
check-helm-bin:
	helm version -c --short|egrep 'v2[.]1[3-9]'

# Packaged infra charts need to be locally available to
# package main openstack-helm charts: run 'helm serve'
# on top of infra dir
helm-serve:
	helm init --client-only
	pkill helm; helm serve --repo-path $(REPO_ROOT)/openstack-helm-infra & sleep 2
	helm repo remove stable || true
	helm repo remove local || true
	helm repo add local http://localhost:8879/charts

# Package all openstack-helm charts
package-osh-charts:
	$(MAKE) -C $(REPO_ROOT)/openstack-helm all

# Destroy the deployment by removing the running charts deploy,
# PVs will persist, also creds are not resetted so a new deploy
# should work.
os-destroy:
	helm ls --namespace=openstack -q|xargs -tr helm delete --purge
	kubectl delete job,pod,cm --namespace=openstack --all --grace-period=1

# DANGER: this will completely destroy the openstack deploy,
# including its PVs (deleting the NS) and the credentials
os-destroy-all: os-destroy
	kubectl delete ns openstack || true
	sudo rm -rf /etc/openstack

# Wrap git-clone target (from Makefile.common) to be used as:
# make git-clone-openstack-helm (ditto openstack-helm-infra)
git-clone-%:
	$(MAKE) git-clone REPO=$(REPO_OS_ROOT)/$(*).git REPO_DIR=$(REPO_ROOT)/$(*)

# Setup python venv for openstack CLI tools
install-venv:
	$(TEST_VENV) && exit 0; $(SETUP_VENV) && $(USE_VENV) && \
		pip3 install --upgrade pip && \
		pip3 install $(PIP_PKGS)
.PHONY: init prep creds tests deploy setup-client git-clone-% install-venv os-%
.PRECIOUS: $(OSH_PASSWORDS_ENV)
