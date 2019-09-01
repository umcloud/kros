#!/bin/bash -x
# Manual octavia deploy from ongoing PR request at https://review.opendev.org/#/c/630821/ ,
# patch below snapshot on 2019-08-30
. .venv/bin/activate || exit 1
cd ../repos/openstack-helm || exit 1
# patch -N -p1 < ../os/patches/openstack-helm/octavia-7e115c9.20190901.diff
test -d octavia || {
    echo "ERROR: need to patch-in octavia, e.g:"
    echo "cd $PWD && patch -N -p1 < ../os/patches/openstack-helm/octavia-7e115c9.20190901.diff"
    exit 1
}
# Manually run each of the 2 octavia resources creation scripts,
# needed before helm chart deploy
sed 's/sudo pip install/pip install/' ./tools/deployment/developer/common/180-create-resource-for-octavia.sh | bash -x
bash -x ./tools/deployment/developer/common/190-create-octavia-certs.sh
# Deploy octavia chart, default to known OSH_EXTRA_HELM_ARGS to allow
# manually running this script
: ${OSH_EXTRA_HELM_ARGS:='-f /etc/openstack/os-charts-values.yaml'}
export OSH_EXTRA_HELM_ARGS
bash -x tools/deployment/developer/common/200-octavia.sh
