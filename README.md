# KROS: Kubernetes + Rook + OpenStack over metal

As per https://twitter.com/xjjo/status/1119736402571407361

Our #KROSK approach:
* `_K`: @kubernetesio on metal (via @kubespray )
* `_R`: @rook_io on `_K`
* `_OS`: @OpenStack on `_K` (via openstack-helm) using _R for persistence
* `_K`: (many) end-user #k8s on `_OS` / `_R` (not in this `kros` repo on
  purpose)

**NOTE this is much WIP/PoC stage**, the instrumenting Makefiles here
are 'sucked` live :) into this repo as we verify the components'
integration, essentially to validate the approach with the least
effort, then later to improve them (many `TODO`s still).

As of 2019/04/21, this PoC seems to be working, from smoke-testing the `_OS`:

* `glance`: Ok, using `rbd` backend (rook-ceph cluster), got default
  cirrus image auto-loaded by deploy
* `cinder`: Ok creating a simple volume, didn't test attaching tho
* `neutron`: create the needed neutron resources (net, subnet, router)
* `nova`: spawn an instance Ok, validating neutron agents and glance
  service setup

## k/ Kubespray
TODO.

## r/ Rook

See `r/README.md`.

## os/ OpenStack
TODO.
