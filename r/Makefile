REPO=https://github.com/rook/rook
REPO_DIR=$(REPO_ROOT)/rook
REPO_COMMIT=v1.0.4

ROOK_MANIFESTS=$(REPO_DIR)/cluster/examples/kubernetes/ceph/{operator,cluster,storageclass,toolbox,common}.yaml


help:
	@echo make prep
	@echo make diff
	@echo make deploy
	@echo make show

include ../Makefile.common

prep: debug git-clone configs-copy req-kustomize
	./scripts/10-do-prep.sh $(NODES)

diff:
	git diff configs/

deploy:
	./scripts/20-do-deploy.sh $(CURDIR)/configs

show:
	./scripts/30-do-show.sh ceph status
	./scripts/30-do-show.sh ceph osd tree

configs-copy:
	cp -pv -t ./configs $(ROOK_MANIFESTS)

gen-nodes:
	@./scripts/generate-nodes.sh $(NODES)

req-%:
	@which $(*) >/dev/null || $(call missing,$(*))

HELP_kustomize := -- install from https://github.com/kubernetes-sigs/kustomize
missing = { $(eval HELP=$(HELP_$(1))) echo "ERROR: missing $(1) $(HELP)"; exit 1; }
