# Rook

Rook is deployed by cloning https://github.com/rook/rook then locally
copying Kubernetes manifests and modifying `cluster.yaml` into
`cluster-all.yaml` with all existing nodes explicitly listed with
each `/srv/ceph/...` storage.

## Deploy

Follow `make help` (default target if you just `make`):

    make
    make prep
    make diff
    make deploy
    make show

Where:
* `make prep` will create `cluster-all.yaml` by ssh'ing into all
  existing nodes, _grepping_ for `/srv/ceph/...` mountpoints, adding
  them as nodes to that manifest (you can see its intermediate output
  at `r/configs/cluster-extra.yaml`
* `make diff` is important to assess what would change on `make
  deploy`
* `make deploy` is idempotennt, we you can run it against existing deploy
* `make show` will do e.g. `ceph status` using deployed rook _toolbox_
