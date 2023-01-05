
# Cluster API with vcluster provider

## Motivation

Experiment with different tools to provision on-demand clusters.

This implementation uses a combination of the [Cluster API](https://github.com/kubernetes-sigs/cluster-api) standard developed by 
the Kubernetes Cluster Lifecycle SIG to promote a common standard on which clusters are defined and managed, and VCluster developed by loft.sh to make it possible to provision standard compliant k8s clusters virtually inside an existing cluster.

## Prerequisites

* [docker](https://www.docker.com/products/docker-desktop/)
* [kubectl](https://kubernetes.io/docs/tasks/tools/)
* [kind](https://kind.sigs.k8s.io/docs/user/quick-start/)
* [clusterctl](https://cluster-api.sigs.k8s.io/user/quick-start.html#install-clusterctl)
* [vcluster cli](https://www.vcluster.com/docs/getting-started/setup)

## Create the bootstrap cluster

This cluster is intended to use a temporary cluster that is used to provision a Target Management cluster where one or more Infrastructure Providers run, and where resources (e.g. Machines) are stored. Typically referred to when you are provisioning multiple workload clusters.

In this example we are mounting the underlying docker unix socket to provide docker-in-docker capabilities in case we also want to install the default Docker infra provider.

```yaml
kind: Cluster
apiVersion: kind.x-k8s.io/v1alpha4
nodes:
- role: control-plane
  extraMounts:
    - hostPath: /var/run/docker.sock
      containerPath: /var/run/docker.sock
```

```sh
kind create cluster --config kind-bootstrap-cluster.yaml
```

Make sure that you have loaded the kubeconfig for the provisioned bootstrap cluster. This is usually done automatically after `kind create` exits successfully.

Then install the vcluster provider to the cluster:

```sh
clusterctl init --infrastructure vcluster
```

> **NOTE**:
  this can be run multiple times for every provider 
  you want to install. The first run will also install `kubeadm` control-plane and bootstrapper. See [clusterctl init](https://cluster-api.sigs.k8s.io/clusterctl/commands/init.html) for more information.


By this point we are ready to provision virtual clusters through the standard Cluster API interface. You can easily generate these declarative manifests with the following command:

```sh
export HELM_VALUES="service:\n  type: NodePort"
clusterctl generate cluster worker-cluster > worker-cluster.yaml
```

It will look something like this:

```yaml
apiVersion: cluster.x-k8s.io/v1beta1
kind: Cluster
metadata:
  name: worker-cluster
  namespace: vcluster
spec:
  controlPlaneRef:
    apiVersion: infrastructure.cluster.x-k8s.io/v1alpha1
    kind: VCluster
    name: worker-cluster
  infrastructureRef:
    apiVersion: infrastructure.cluster.x-k8s.io/v1alpha1
    kind: VCluster
    name: worker-cluster
---
apiVersion: infrastructure.cluster.x-k8s.io/v1alpha1
kind: VCluster
metadata:
  name: worker-cluster
  namespace: vcluster
spec:
  controlPlaneEndpoint:
    host: ""
    port: 0
  helmRelease:
    chart:
      name: null
      repo: null
      version: null
    values: |-
      service:
        type: NodePort
  kubernetesVersion: 1.25.5

```

Apply the manifest to the cluster and wait for the virtual cluster to get ready.

```sh
kubectl apply -f worker-cluster.yaml

# ensure PHASE=Provisioned before connecting
kubectl get clusters
```

The cluster should be ready in a short amount of time and you can try and connect to it with the vcluster cli:

```sh
vcluster connect worker-cluster
```

Congratulations! You can now deploy workload to this virtual cluster as clusteradmin in isolation.