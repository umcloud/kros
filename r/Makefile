REPO=https://github.com/rook/rook
REPO_DIR=$(REPO_ROOT)/rook

ROOK_MANIFESTS=$(REPO_DIR)/cluster/examples/kubernetes/ceph/{operator,cluster,storageclass,toolbox}.yaml

help:
	@echo make prep
	@echo make diff
	@echo make deploy
	@echo make show

include ../Makefile.common

prep: debug git-clone do-prep

do-prep:
	./scripts/10-do-prep.sh $(REPO_DIR)/cluster/examples/kubernetes/ceph $(CURDIR)/configs $(NODES)

diff:
	git diff configs/

deploy:
	./scripts/20-do-deploy.sh $(CURDIR)/configs

show:
	./scripts/30-do-show.sh ceph status
	./scripts/30-do-show.sh ceph osd tree

gen-nodes:
	@./scripts/generate-nodes.sh $(NODES)

