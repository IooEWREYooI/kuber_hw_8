#!/bin/bash

# Master node setup
set -e

echo "=== Setting up Kubernetes master node ==="

# Wait for containerd to be ready
echo "Waiting for containerd..."
sudo systemctl status containerd --no-pager

# Initialize the cluster
echo "Initializing Kubernetes cluster..."
sudo kubeadm init --pod-network-cidr=10.244.0.0/16 --apiserver-advertise-address=192.168.56.10

# Set up kubectl for the current user
echo "Setting up kubectl..."
mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config

# Install Calico network plugin
echo "Installing Calico network plugin..."
kubectl apply -f https://raw.githubusercontent.com/projectcalico/calico/v3.27.0/manifests/calico.yaml

# Wait for control plane to be ready
echo "Waiting for control plane to be ready..."
kubectl wait --for=condition=Ready node/$(hostname) --timeout=300s

# Generate join command for workers
echo "Generating join command..."
JOIN_COMMAND=$(sudo kubeadm token create --print-join-command)

# Save join command to a file that can be accessed by workers
echo "$JOIN_COMMAND" > /tmp/kubeadm_join

echo "=== Master setup completed ==="
echo ""
echo "Join command for worker nodes:"
echo "$JOIN_COMMAND"
