PIP_PKGS=wheel "cmd2<=0.8.7" python-openstackclient python-heatclient
SETUP_VENV=pyvenv .venv
USE_VENV=source .venv/bin/activate
OS_PASSWORD_FILE=$$HOME/.openstack.pass

REPO_OS_ROOT=https://git.openstack.org/openstack

help:
	@echo make init
	@echo make prep

include ../Makefile.common

# Steps from https://docs.openstack.org/openstack-helm/latest/install/developer/kubernetes-and-common-setup.html
init: git-clone-openstack-helm git-clone-openstack-helm-infra git-clone-2 install-venv

prep: 020-setup-client

020-setup-client:
	sudo install -o $$(id -nu) -d /etc/openstack
	test -f $(OS_PASSWORD_FILE) || openssl rand -base64 18 > $(OS_PASSWORD_FILE)
	sed -e "s|password:.*|password: $$(cat $(OS_PASSWORD_FILE))|" \
	    -e "s/-xe/-e/" \
	    -e "/pip /d" \
		$(REPO_ROOT)/openstack-helm/tools/deployment/developer/common/020-setup-client.sh \
		> $(CURDIR)/configs/020-setup-client.sh
	helm init --client-only
	test -L $(ROOT_DIR)/charts || ln -s repos $(ROOT_DIR)/charts
	pkill helm; helm serve --repo-path $(REPO_ROOT)/openstack-helm & sleep 5 && \
		helm repo add local http://localhost:8879/
	cd $(REPO_ROOT)/openstack-helm && bash $(CURDIR)/configs/020-setup-client.sh

git-clone-%:
	$(MAKE) git-clone REPO=$(REPO_OS_ROOT)/$(*).git REPO_DIR=$(REPO_ROOT)/$(*)

install-venv:
	$(SETUP_VENV) && $(USE_VENV) && \
		pip3 install --upgrade pip && \
		pip3 install $(PIP_PKGS)
.PHONY: init git-clone-% install-venv
