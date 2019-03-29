#!/bin/bash
fstype=xfs
prefix=/srv/ceph
nodes=${*:?missing nodes}
## Generate per-node cluster.yaml stanza for ROOK in the form of:
##     nodes:
##     - name: node01
##       directories:
##       - /srv/ceph/ceph1
echo      "    nodes:"
printf "%s\n" ${nodes:?} | xargs -I% ssh -l ubuntu % $'sh -c \'
  echo    "    - name: %"
  echo -n "      directories:"
  m=$(mount --type '${fstype:?}'|egrep -o " '${prefix:?}$'\S*"|sed "s,^,      - path:,")
  [ -n "$m" ] && echo "\n$m" || echo " []"
\''
