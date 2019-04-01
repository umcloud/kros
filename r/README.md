# Rook

Rook is deployed by cloning https://github.com/rook/rook then locally
copying Kubernetes manifests and modifying them as needed into
`./config/` directory.

## Deploy

Follow `make help` (default target if you just `make`):

    make
    make prep
    make diff
    make deploy
    make show

Where:
* `make prep` will copy and modify upstream kubernetes manifests:
  * `operator.yaml`: copied verbatim
  * `cluster.yaml`: modified to explicitly set storage for each node
  (by ssh'ing into all existing nodes, _grepping_ for `/srv/ceph/...`
  mountpoints, adding them as nodes to the manifest, you can see the
  intermediate output at `configs/cluster.yaml.add`
  * `storageclass.yaml`: modified to set RF=3 (osd pool size)
  * `toolbox.yaml`: copied verbatim
* `make diff` is important to assess what would change on `make
  deploy` from `configs/` diffs
* `make deploy` is idempotennt, we you can run it against existing
  deploy, it's essentially `kubectl apply -f ...` over configs/
  manifests
* `make show` will do e.g. `ceph status` using deployed rook _toolbox_

## Unittests

To run simple YAML unitests to cover `cluster.yaml` manipulation, do

    make tests
