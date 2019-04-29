# OpenStack

OpenStack is deployed via openstack-helm, by running its deployment
scripts via mods as needed, with charts values overridden by
`configs/os-charts-values.tmpl.yaml` (templated `values.yaml` parsed
via `make creds`).

copying Kubernetes manifests and modifying `cluster.yaml` into
`cluster-all.yaml` with all existing nodes explicitly listed with
each `/srv/ceph/...` storage.

## Deploy

Follow `make help` (default target if you just `make`):

    make
    make init
    make prep
    make creds
    make tests
    make deploy


Where:
* `make init` will clone repos
* `make prep` will prepare the charts, which need to be packages
  (while also running a `helm serve` instance for openstack-helm-infra
  charts), also running `ceph-client-conf` target to create below
  kubernetes resources at the `openstack` NS:
  * `ceph-etc` ConfigMap: needed as we're not deploying openstack-helm
    ceph component but rather using Rook's
  * `cepn-mon-0,1,2` Services: ExternalName svcs pointing to running
    `rook-ceph-mon-a,b,c` (which may flip to d,e,f...) under
    `rook-ceph` NS
* `make deploy` will run all deployment scripts for `DEPLOY_TYPE`
  (`multinode` by default)

## Known issues:

### Calico

Calico CNI firewall rules interfere with VXLAN and GRE tunneling,
in concrete their packets get `DROP` -ed by `cali-OUTPUT` chain rules.

To workaround these, below rule will ab-use Calico's `ACCEPT` -ed mark
at `cali-OUTPUT` chain, by applying it to the tunneled packets we want
to void getting dropped (add it at nodes' initialization scripts):

    /sbin/iptables -t mangle -I OUTPUT -p GRE -j MARK --set-xmark
    0x10000/0x10000

### Crashlooping libvirt-libvirt-default daemonset Pods

One some nodes, depending on their workload, you may find steady
libvirt crashlooping pods, these log to node's `/var/log/libvirt/libvirtd.log`,
peeking there you

  2019-04-21 01:51:22.581+0000: 7363: error : virSecurityDriverLookup:80 : unsupported configuration: Security driver apparmor not enabled
  2019-04-21 01:51:22.581+0000: 7363: error : umlStateInitialize:566 : Failed to create inotify watch on /var/run/libvirt/uml-guest: No space left on device
  2019-04-21 01:51:22.581+0000: 7363: error : virStateInitialize:783 : Initialization of UML state driver failed: unsupported configuration: Security driver apparmor not enabled

To fix these, increase the amount of inotify watchers at nodes, via e.g.:

  echo fs.inotify.max_user_watches=524288 | sudo tee -a /etc/sysctl.conf && sudo sysctl -p

### ceph-mons

See `update-ceph-mon-openstack-svc` Makefile target.

### DNS
