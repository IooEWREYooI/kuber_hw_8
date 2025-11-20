#!/bin/bash

# Worker node setup
set -e

echo "=== Setting up Kubernetes worker node ==="

# Wait for containerd to be ready
echo "Waiting for containerd..."
sudo systemctl status containerd --no-pager

# Wait for master to be ready
echo "Waiting for master node to be ready..."
sleep 60

# Get join command from master (this is a simplified version for demo)
# In production, you'd securely transfer the join command
echo "Getting join command from master..."
JOIN_COMMAND="sudo kubeadm join 192.168.56.10:6443 --token $(docker exec k8s-master kubeadm token create) --discovery-token-ca-cert-hash sha256:$(docker exec k8s-master openssl x509 -pubkey -in /etc/kubernetes/pki/ca.crt | openssl rsa -pubin -outform der 2>/dev/null | openssl dgst -sha256 -hex | sed 's/^.* //')"

echo "Joining Kubernetes cluster..."
eval "$JOIN_COMMAND"

echo "=== Worker setup completed ==="
