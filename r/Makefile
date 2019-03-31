REPO=https://github.com/rook/rook
REPO_DIR=$(REPO_ROOT)/rook

MANIFESTS_DIR=$(REPO_DIR)/cluster/examples/kubernetes/ceph

help:
	@echo "make prep     # Clone rook repo, prepara manifests at configs/"
	@echo "make tests    # Run unit-tests that would spot bad manifests mangling"
	@echo "make diff     # Show manifests diffs"
	@echo "make deploy   # Deploy Rook (from scratch, or on top of existing)"
	@echo "make show     # Show ceph status and alike"

include ../Makefile.common

prep: debug git-clone do-prep

do-prep:
	./scripts/10-do-prep.sh $(MANIFESTS_DIR) $(CURDIR)/configs $(NODES)

diff:
	git diff configs/

deploy:
	./scripts/20-do-deploy.sh $(CURDIR)/configs

show:
	./scripts/30-do-show.sh ceph status
	./scripts/30-do-show.sh ceph osd tree

tests:
	$(MAKE) -C tests MANIFESTS_DIR=$(MANIFESTS_DIR)

gen-nodes:
	@./scripts/generate-nodes.sh $(NODES)

.PHONY: help prep do-prep diff deploy show tests gen-nodes
