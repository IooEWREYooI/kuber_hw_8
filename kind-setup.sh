#!/bin/bash

# Kubernetes cluster setup using kind (Kubernetes in Docker)
set -e

echo "=== Setting up Kubernetes cluster with kind ==="

# Install kind if not present
if ! command -v kind &> /dev/null; then
    echo "Installing kind..."
    curl -Lo ./kind https://kind.sigs.k8s.io/dl/v0.24.0/kind-linux-amd64
    chmod +x ./kind
    sudo mv ./kind /usr/local/bin/kind
fi

# Create kind configuration
cat <<EOF > kind-config.yaml
kind: Cluster
apiVersion: kind.x-k8s.io/v1alpha4
nodes:
- role: control-plane
  kubeadmConfigPatches:
  - |
    kind: InitConfiguration
    nodeRegistration:
      kubeletExtraArgs:
        node-labels: "ingress-ready=true"
  extraPortMappings:
  - containerPort: 80
    hostPort: 80
    protocol: TCP
  - containerPort: 443
    hostPort: 443
    protocol: TCP
- role: worker
- role: worker
- role: worker
- role: worker
EOF

# Create cluster
echo "Creating kind cluster..."
kind create cluster --name k8s-cluster --config kind-config.yaml

# Verify cluster
echo "Verifying cluster..."
kubectl cluster-info --context kind-k8s-cluster
kubectl get nodes

echo "=== Cluster setup completed ==="
echo ""
echo "To use the cluster:"
echo "kubectl cluster-info --context kind-k8s-cluster"
echo "kubectl get nodes"
echo ""
echo "To delete the cluster:"
echo "kind delete cluster --name k8s-cluster"
