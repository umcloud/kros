# Deploy root-ceph operator cluster storageclass toolbox
deploy_node_custom_setup() {
    (set -x; kubectl apply -f ${CONFIG_DIR}/00-node-custom-setup.yaml)
    echo -n "Wait for node-custom-setup: "
    until [ $(kubectl get pod -n kube-system -l k8s-app=node-custom-setup|egrep node-custom-setup|egrep -cv Running) -eq 0 ]; do
      echo -n .
    done
    echo
}

deploy_common() {
    (set -x; kubectl apply -f ${CONFIG_DIR}/common.yaml)
}
deploy_operator() {
    # No mods:
    (set -x; kubectl apply -f ${CONFIG_DIR}/operator.yaml)
    echo -n "Wait for cluster CRD to be ready: "
    until kubectl get crd cephclusters.ceph.rook.io 2>/dev/null; do echo -n .; sleep 1;done
    echo
}

deploy_cluster() {
    (set -x; kubectl apply -f ${CONFIG_DIR}/cluster-all.yaml)
}

deploy_sc_and_toolbox() {
    # No mods
    (set -x
    kubectl apply -f ${CONFIG_DIR}/storageclass.yaml
    kubectl apply -f ${CONFIG_DIR}/toolbox.yaml
    )
    echo "Switching default storageclass to rook-ceph:"
    kubectl get sc
    kubectl get sc |awk '/default/{ print $1 }'|xargs -I@ kubectl patch sc @ -p '{"metadata": {"annotations": { "storageclass.kubernetes.io/is-default-class": "false"}}}'
    kubectl get sc |awk '/rook/{ print $1 }'   |xargs -I@ kubectl patch sc @ -p '{"metadata": {"annotations": { "storageclass.kubernetes.io/is-default-class": "true"}}}'
    kubectl get sc
}
CONFIG_DIR=${1:?missing arg1: CONFIG_DIR}
set -e
deploy_node_custom_setup
deploy_common
deploy_operator
deploy_cluster
deploy_sc_and_toolbox
