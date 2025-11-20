#!/bin/bash

# Docker-based Kubernetes cluster setup
set -e

echo "=== Creating Kubernetes cluster with Docker containers ==="

# Create a custom network for the cluster
echo "Creating Docker network..."
docker network create --subnet=192.168.56.0/24 k8s-cluster || true

# Function to create a node
create_node() {
    local name=$1
    local ip=$2

    echo "Creating node: $name with IP: $ip"

    docker run -d \
        --name $name \
        --hostname $name \
        --network k8s-cluster \
        --ip $ip \
        --privileged \
        --tmpfs /tmp \
        --tmpfs /run \
        --tmpfs /run/lock \
        -v /sys/fs/cgroup:/sys/fs/cgroup:ro \
        -v $name-data:/var/lib \
        ubuntu:20.04 \
        sleep infinity

    # Wait for container to start
    sleep 2

    # Install systemd in container (needed for kubelet)
    docker exec $name bash -c "
        apt-get update && \
        apt-get install -y systemd systemd-sysv && \
        systemctl start systemd-journald
    "

    # Copy setup scripts to container
    docker cp scripts/common.sh $name:/tmp/common.sh
    docker cp scripts/$3.sh $name:/tmp/setup.sh

    # Make scripts executable and run them
    docker exec $name chmod +x /tmp/common.sh /tmp/setup.sh

    echo "Running common setup on $name..."
    docker exec $name /tmp/common.sh

    echo "Running $3 setup on $name..."
    docker exec $name /tmp/setup.sh
}

# Create master node
create_node "k8s-master" "192.168.56.10" "master"

# Create worker nodes
for i in {1..4}; do
    create_node "k8s-worker$i" "192.168.56.$((10 + i))" "worker"
done

echo "=== Cluster creation completed ==="
echo ""
echo "To access the cluster:"
echo "docker exec -it k8s-master bash"
echo "kubectl get nodes"
echo ""
echo "To clean up:"
echo "docker rm -f k8s-master k8s-worker1 k8s-worker2 k8s-worker3 k8s-worker4"
echo "docker network rm k8s-cluster"
echo "docker volume rm k8s-master-data k8s-worker1-data k8s-worker2-data k8s-worker3-data k8s-worker4-data"
