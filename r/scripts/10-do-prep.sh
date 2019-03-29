# Deploy root-ceph operator
prep_cluster() {
    local cluster_extra=$(dirname ${CLUSTER_DST})/cluster-extra.yaml
    echo "Creating extra custom '${CLUSTER_DST}' per-node setup ..."
    ${MY_DIR}/generate-nodes.sh ${NODES:?} > ${cluster_extra}
    test -s ${cluster_extra} || { echo "FATAL: ${cluster_extra} in zero" ; exit 1 ;}
    set -e
    (sed -e '/useAllNodes:/s/true/false/;/Cluster.level.list/,$d' ${CLUSTER_SRC} && cat ${cluster_extra}) > ${CLUSTER_DST}
}
MY_DIR=$(dirname ${0})
CLUSTER_SRC=${1:?missing arg1: CLUSTER_SRC (cluster.yaml)}
CLUSTER_DST=${2:?missing arg2: CLUSTER_DST (cluster-all.yaml)}
shift 2
NODES=${*:? missing args: NODES}
set -e
prep_cluster
