ROOK_REPO=$(REPO_DIR)/rook
ROOK_MANIFESTS=$(ROOK_REPO)/cluster/examples/kubernetes/ceph/{operator,cluster,storageclass,toolbox}.yaml

help:
	@echo make prep
	@echo make diff
	@echo make deploy
	@echo make show

include ../Makefile.common

prep: debug git-clone configs-copy
	./scripts/10-do-prep.sh $(CURDIR)/configs/cluster.yaml $(CURDIR)/configs/cluster-all.yaml $(NODES)

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

# Set REPO to use for cloning
git-clone: REPO=https://github.com/rook/rook
git-clone:
	@cd $(REPO_DIR); test -d $(ROOK_REPO) && echo "Already cloned: $(REPO) into $(ROOK_REPO)" && exit 0; git clone --depth=1 $(REPO) $(ROOK_REPO)
