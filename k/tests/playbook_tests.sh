#!/bin/sh
set -e
echo "Verifying hosts.yaml for ansible-playbook --list-tasks"
ansible-playbook -i ../configs/inventory/cluster/hosts.yaml ${REPO_DIR:?}/cluster.yml --list-tasks | grep play
echo "PASS"
echo "Verifying hosts.yaml for expected NODES: ${NODES:?}"
LIST_HOSTS=$(ansible-playbook -i ../configs/inventory/cluster/hosts.yaml ${REPO_DIR:?}/cluster.yml --list-hosts)
for i in ${NODES}; do
    echo "${LIST_HOSTS}" | grep -q "${i}" || {
        echo "ERROR: node '${i}' not found in 'ansible-playbook --list-hosts' output ->"
        echo "${LIST_HOSTS}"
        exit 1
    }
    echo "  Ok: $i"
done
echo "PASS"
