export CLUSTER_NAME=worker-cluster
export CLUSTER_NAMESPACE=vcluster
export KUBERNETES_VERSION=1.25.5
export HELM_VALUES="service:\n  type: NodePort"

# kubectl create namespace ${CLUSTER_NAMESPACE}
clusterctl generate cluster ${CLUSTER_NAME} \
    --infrastructure vcluster \
    --kubernetes-version ${KUBERNETES_VERSION} \
    --target-namespace ${CLUSTER_NAMESPACE} > worker-cluster.yaml