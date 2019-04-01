#!/bin/bash
fstype=${GN_FSTYPE:-xfs}
prefix=${GN_PREFIX:-/srv/ceph}
ssh_cmd=${GN_SSH_CMD:-ssh -l ubuntu %s}
nodes=${*:?missing nodes}
## Generate per-node cluster.yaml stanza for ROOK in the form of:
##     nodes:
##     - name: node01
##       directories:
##       - /srv/ceph/ceph1
echo      "    nodes:"
printf "%s\n" ${nodes:?} | xargs -I%s ${ssh_cmd} $'sh -c \'
  echo    "    - name: %s"
  echo -n "      directories:"
  m=$(mount --type '${fstype:?}'|egrep -o " '${prefix:?}$'\S*"|sed "s,^,      - path:,")
  [ -n "$m" ] && echo "\n$m" || echo " []"
\''
