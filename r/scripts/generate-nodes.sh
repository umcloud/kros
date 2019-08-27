#!/bin/bash
fstype=xfs
prefix=/srv/ceph
nodes=${*:?missing nodes}
## Generate per-node cluster.yaml stanza for ROOK in the form of:
##     nodes:
##     - name: node01
##       directories:
##       - /srv/ceph/ceph1
cat << EOF
apiVersion: ceph.rook.io/v1
kind: CephCluster
metadata:
  name: any
spec:
  storage:
    nodes:
EOF
printf "%s\n" ${nodes:?} | xargs -I% ssh -o StrictHostKeyChecking=no -l ubuntu % $'sh -c \'
  echo    "    - name: %"
  echo -n "      directories:"
  m=$(mount --type '${fstype:?}'|egrep -o " '${prefix:?}$'\S*"|sed "s,^,      - path:,"|sort)
  [ -n "$m" ] && echo "\n$m" || echo " []"
\''
