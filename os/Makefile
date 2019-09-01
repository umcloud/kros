PIP_PKGS=wheel "cmd2<=0.8.7" python-openstackclient python-heatclient
# Helper vars for python venv
SETUP_VENV=pyvenv .venv
USE_VENV=source .venv/bin/activate
TEST_VENV=test -f .venv/bin/activate

SVC_CLUSTER=svc.metal.kube.um.edu.ar

# Ceph integration
ROOK_CEPH_NS=rook-ceph
ROOK_CEPH_NS_FQDN=$(ROOK_CEPH_NS).$(SVC_CLUSTER)
CEPH_ADMIN_KEYRING_ENV=/etc/openstack/ceph-admin-keyring.env

# TODO(jjo): get from chart vars, should be svc.umcloud.local
OS_DOMAIN=openstack.$(SVC_CLUSTER)

KEYSTONE_FQDN=keystone.$(OS_DOMAIN)
KEYSTONE_FQDN_HOSTS=$(KEYSTONE_FQDN) $(shell echo {keystone,cinder,glance,neutron,nova,placement,heat}{,-api}.$(OS_DOMAIN))

# DEPLOY_TYPE can be: developer/common (dev) or multinode (prod)
DEPLOY_TYPE=multinode
#DEPLOY_TYPE=developer/common
# TODO(jjo): adapt ceph stuff to Rook
# NOTE: compute-kit includes: nova, neutron
# F_ck... it REALLY wants its own ingress (!): installs in kube-system *and* openstack NS ("ingress" Pods)
DEPLOY_GREP='mariadb|rabbitmq|ingress|memcached|keystone|glance|cinder|openvswitch|libvirt|compute-kit|heat|Xceph-radosgateway|horizon'

# @navarrow won't let me go without horizon ...
DEPLOY_SCRIPTS_BASE=$(shell ls $(REPO_ROOT)/openstack-helm/tools/deployment/$(DEPLOY_TYPE)/[0-9]* |egrep $(DEPLOY_GREP))
DEPLOY_SCRIPTS_EXTRA=$(shell ls $(REPO_ROOT)/openstack-helm/tools/deployment/developer/common/100-horizon.sh | egrep $(DEPLOY_GREP))
DEPLOY_SCRIPTS=$(DEPLOY_SCRIPTS_BASE) $(DEPLOY_SCRIPTS_EXTRA)
OSH_PASSWORDS_ENV=/etc/openstack/osh-passwords.env
OPENSTACK_CLOUDS=/etc/openstack/clouds.yaml
CHARTS_VALUES_YAML=/etc/openstack/os-charts-values.yaml
OSH_EXTRA_HELM_ARGS_BASE="-f $(CHARTS_VALUES_YAML)"

export OPENSTACK_RELEASE=rocky

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

prep: etc-openstack check-helm-bin helm-serve package-infra-charts package-osh-charts label-kube-nodes ceph-client-conf

creds: etc-openstack os-charts-values setup-client

tests: os-test-bad-passwords

deploy: os-deploy

etc-openstack:
	sudo install -m 0700 -o $$(id -nu) -d /etc/openstack

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
	#kubectl label nodes openstack-control-plane=enabled -l node-role.kubernetes.io/master --overwrite
	kubectl label nodes openstack-control-plane=enabled --all --overwrite
	kubectl label nodes openstack-helm-node-class=primary -l node-role.kubernetes.io/master --overwrite
	kubectl label nodes ceph-rgw=enabled -l node-role.kubernetes.io/master --overwrite
	kubectl label nodes openstack-compute-node=enabled --all --overwrite
	kubectl label nodes openvswitch=enabled --all --overwrite

ceph-client-conf: $(CEPH_ADMIN_KEYRING_ENV) update-ceph-mon-openstack-svc
	kubectl create ns openstack || true
	@# used-by: glance (secret/pvc-ceph-client-key)
	. $(CEPH_ADMIN_KEYRING_ENV) && kubectl create secret generic --namespace=openstack pvc-ceph-client-key --dry-run --from-literal=key=$${CEPH_ADMIN_KEYRING:?} -oyaml  | kubectl apply -f-
	kubectl get cm -n openstack ceph-etc -ojson | jq -r '.data["ceph.conf"]'

# rook-ceph mon endpoints can change if the rook operator finds
# the need to replace an outage-d mon, e.g. could switch from mon-a,b,c
# to mon-d,e,f (with different IPs)
# Here we add "stable" ceph-mon-0,1,2 ExternalName svcs at the openstack NS,
# this target will update these to point to *currently* running ones
update-ceph-mon-openstack-svc:
	$(MAKE) -s env-ceph-mons ROOK_CEPH_NS=$(ROOK_CEPH_NS) |egrep ^export > configs/ceph-mon-openstack.env
	-kubectl create ns openstack
	. configs/ceph-mon-openstack.env && envsubst < configs/ceph-mon-openstack.tmpl.yaml | kubectl apply -f-
	kubectl create cm --namespace=openstack ceph-etc --dry-run --from-file=configs/ceph-etc -oyaml | kubectl apply -f-
	kubectl get svc -n openstack -l app=ceph-mon

# Show env needed to update ceph-mon-0,1,2 entries from ceph-mon-openstack.yaml as e.g.:
# Note we're using hostNetwork: true for the mons, to keep them at a stable IP:PORT
# export MON_0=<hostIP node1>
# export MON_1=<hostIP node2>
# export MON_2=<hostIP node3>
env-ceph-mons:
	kubectl get pod -n ${ROOK_CEPH_NS} -l app=${ROOK_CEPH_NS}-mon -l mon -ogo-template='{{range $$i, $$e :=.items}}export MON_{{$$i}}={{.status.hostIP}}.xip.io{{"\n"}}{{end}}'

hack-etc-hosts:
	$(eval INGRESS_IP=$(shell kubectl get svc -n ingress-nginx ingress-nginx -ojsonpath='{.status.loadBalancer.ingress[0].ip}'))
	@test $(INGRESS_IP) != ""
	egrep $(KEYSTONE_FQDN) /etc/hosts && \
		sudo sed -i.bak '/$(KEYSTONE_FQDN)/s/.*/$(INGRESS_IP) $(KEYSTONE_FQDN_HOSTS)/' /etc/hosts || \
		{ echo $(INGRESS_IP) $(KEYSTONE_FQDN_HOSTS) | sudo tee -a /etc/hosts; }

$(CHARTS_VALUES_YAML): configs/os-charts-values.tmpl.yaml $(OSH_PASSWORDS_ENV) $(CEPH_ADMIN_KEYRING_ENV) Makefile
	. $(OSH_PASSWORDS_ENV) && . $(CEPH_ADMIN_KEYRING_ENV) && envsubst < $(<) > $(@)

$(OSH_PASSWORDS_ENV):
	sed -e '/set -xe/d' -e 's|/tmp/osh-passwords.env|$(OSH_PASSWORDS_ENV)|' $(REPO_ROOT)/openstack-helm/tools/deployment/armada/generate-osh-passwords.sh| bash

$(CEPH_ADMIN_KEYRING_ENV): Makefile
	$(eval CEPH_ADMIN_KEYRING=$(shell kubectl get secrets --namespace=$(ROOK_CEPH_NS) rook-ceph-admin-keyring -ojsonpath='{.data.keyring}' | base64 -d | sed -rn 's/.*key.=.//p'))
	test -n "$(CEPH_ADMIN_KEYRING)" && \
		printf "export %s\n" \
			"CEPH_ADMIN_KEYRING=$(CEPH_ADMIN_KEYRING)" \
			"ROOK_CEPH_NS_FQDN=$(ROOK_CEPH_NS_FQDN)" \
			"ROOK_CEPH_NS=$(ROOK_CEPH_NS)" \
			> $(@)

# XXX: Sucky integration (Aug/2019): get-values-overrides.sh is NOT available for multinode scripts,
# need to get them myself: scriptlet below to plug inside for loop (relying on `deploy_script` var)
# that will setup `OSH_EXTRA_HELM_ARGS` usable by chart deploy_script-s
set_OSH_EXTRA_HELM_ARGS = \
		components=$$(sed -rn 's/helm.upgrade.--install.(\S+).*/\1/p' $$deploy_script|sort -u | paste -s) ;\
		overrides=$$(for c in $$components; do ./tools/deployment/common/get-values-overrides.sh $$c; done) ;\
		export OSH_EXTRA_HELM_ARGS=$$(echo $$overrides $(OSH_EXTRA_HELM_ARGS_BASE)) ;\
		test $$components = horizon && kubectl delete pod -n openstack horizon-test || true ;\
		echo "components=$$components OSH_EXTRA_HELM_ARGS=$$OSH_EXTRA_HELM_ARGS"

# Do the actual deploy by running DEPLOY_SCRIPTS in sequence,
# DEPLOY_SCRIPTS is filtered-in for only the components we want
# to deploy
# Need to void NETWORK_TUNNEL_DEV=<local_default_route_interface> to avoid using this *local*
# iface on cluster nodes (wtf?)
# On the fly fixes:
# - disable the NETWORK_TUNNEL_DEV logic as this deployment host not necessarily equals nodes (wtf1!)
# - virt_type=qemu by default, REALLY ?!, use =kvm for HW accel (wtf2!)

os-deploy: creds ceph-client-conf
	@echo "Deploying for DEPLOY_TYPE: $(DEPLOY_TYPE), DEPLOY_SCRIPTS: $(DEPLOY_SCRIPTS) ..."
	@$(USE_VENV); cd $(REPO_ROOT)/openstack-helm && \
		for deploy_script in $(DEPLOY_SCRIPTS); do \
		$(set_OSH_EXTRA_HELM_ARGS) ;\
		(echo "=== $$deploy_script ==="; sed -r -e '/tunnel:.*NETWORK_TUNNEL_DEV.*/s/tunnel:/tunnel_broken_disabled:/' -e 's/virt_type=qemu/virt_type=kvm/' $$deploy_script | env PS4='=== ' bash); \
		done

# WIP octavia deploy for lbaas_v2 support,
# utterly manual for now from ongoing upstream PR --jjo, 2019-09-01
os-deploy-octavia:
	OSH_EXTRA_HELM_ARGS=$(OSH_EXTRA_HELM_ARGS_BASE) ./octavia-deploy.sh

# Run 'helm template' instead on each chart, to peek
# at the generated YAML output for the deploy
os-template:
	@cd $(REPO_ROOT)/openstack-helm && export OSH_EXTRA_HELM_ARGS=$(OSH_EXTRA_HELM_ARGS) && \
		for deploy_script in $(DEPLOY_SCRIPTS); do \
		$(set_OSH_EXTRA_HELM_ARGS) ;\
		(sed -r -e '/wait/,$$d' -e 's/helm upgrade --install (\S+)/helm template --name \1/' $$deploy_script| env PS4='=== ' bash); \
		done
# Run 'helm inspect' instead on each chart, to peek
# on charts' settings.
# Note: no OSH_EXTRA_HELM_ARGS for inspect, hacky sed to
# remove all the rest of the script from 'wait' to the end,
os-inspect:
	@cd $(REPO_ROOT)/openstack-helm && \
		for deploy_script in $(DEPLOY_SCRIPTS); do \
		$(set_OSH_EXTRA_HELM_ARGS) ;\
		(sed -r -e '/wait/,$$d' -e '/--namespace|--values|--set|OSH_/d' -e 's/helm upgrade --install \S+ (\S+).*/helm inspect \1/' $$deploy_script| env PS4='=== ' bash) 2>&1 ; \
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
# mariadb PVs will persist, also creds are not resetted so a new deploy
# should work.
os-destroy:
	helm ls --namespace=openstack -q|xargs -tr helm delete --purge
	helm ls --namespace=openstack -q|xargs -tr helm delete --no-hooks --purge
	kubectl delete deploy,sts --namespace=openstack --all
	kubectl delete job,pod,cm --namespace=openstack --all --grace-period=0 --force
	kubectl delete pvc --namespace=openstack -l application=rabbitmq

# DANGER: this will completely destroy the openstack deploy,
# including its PVs (deleting the NS) and the credentials
os-destroy-all: os-destroy
	kubectl delete ns openstack || true
	sudo rm -rf /etc/openstack

# Wrap git-clone target (from Makefile.common) to be used as:
# make git-clone-openstack-helm (ditto openstack-helm-infra)
git-clone-openstack-helm: REPO_COMMIT=3af5f78f5c3f521f61477af9a4676c37ea188fb1
git-clone-openstack-helm-infra: REPO_COMMIT=8f749dd0614e00f29d76e0200b6eac574859f904
git-clone-%:
	$(MAKE) git-clone REPO=$(REPO_OS_ROOT)/$(*).git REPO_DIR=$(REPO_ROOT)/$(*) REPO_COMMIT=$(REPO_COMMIT)

# Setup python venv for openstack CLI tools
install-venv:
	$(TEST_VENV) && exit 0; $(SETUP_VENV) && $(USE_VENV) && \
		pip3 install --upgrade pip && \
		pip3 install $(PIP_PKGS)
.PHONY: init prep creds tests deploy setup-client git-clone-% install-venv os-%
.PRECIOUS: $(OSH_PASSWORDS_ENV)
