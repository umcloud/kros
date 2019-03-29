# Just run passed commands inside root `toolbox`, run interactive
# bash if nothing passed
CMDS=${@:-bash}
echo "INFO: Running in toolbox: ${CMDS}"
kubectl -n rook-ceph exec -it $(kubectl -n rook-ceph get pod -l "app=rook-ceph-tools" -o jsonpath='{.items[0].metadata.name}') -- ${CMDS}
