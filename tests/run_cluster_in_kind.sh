#!/bin/bash
set -e

name="elife-flux-test"
gitserver="$name-gitserver"
repo_root="$(git rev-parse --show-toplevel)"
test_kustomization_path="./clusters/end-to-end-tests"
tests_path="./tests"

# if a param is specified use that branch, otherwise the currently checked out
# one. Either way Flux is pointed at the *local* repository (see below), so it
# reconciles the latest local commit - no git push required.
branch=${1:-$(git branch --show-current)}
if [ -z "$branch" ]; then
    echo "ERROR: no branch given and HEAD is detached; pass a branch name" >&2
    exit 1
fi

echo "Building KinD cluster to test the latest local commit on '$branch'"

kind delete cluster --name "$name"
# tear down any git server left running from a previous run
docker rm --force "$gitserver" >/dev/null 2>&1 || true
kind create cluster --name "$name" --image=kindest/node:v1.34.0

# Serve the local repository to the in-cluster Flux. Flux only supports
# http/https/ssh sources, so instead of a git:// daemon we run a tiny git
# "smart HTTP" server as a container on the same docker network as the KinD
# nodes ("kind"). Cluster pods reach it directly by its container IP, and it
# serves the live .git read-only so Flux sees the latest local commit.
docker build --quiet --tag "$gitserver" "$tests_path/gitserver"
docker run --detach --name "$gitserver" --network kind \
    --volume "$repo_root/.git:/repo/repo.git:ro" "$gitserver" >/dev/null
gitserver_ip="$(docker inspect -f '{{ .NetworkSettings.Networks.kind.IPAddress }}' "$gitserver")"
repo="http://$gitserver_ip/git/repo.git"

# Install Flux with toleration to run controllers on the real node
kubectl create ns flux
# make sure flux components get installed, with additional components
flux install --components-extra="image-reflector-controller,image-automation-controller" --toleration-keys=realnode

# Add label to allow cluster-services workloads to select this node
kubectl label node "$name-control-plane" Project="end-to-end-tests"
# taint the current node to not schedule workloads by default
kubectl taint node "$name-control-plane" realnode=true:NoSchedule
# Add a label for topology tests to work
kubectl label node "$name-control-plane" topology.kubernetes.io/zone=fake-zone-a

# Install gitops stuff and wait
flux create source git flux-system --url="$repo" --branch="$branch"
flux create kustomization flux-system --source=flux-system --path="$test_kustomization_path"
# Force reconcile of all kustomizations
make reconcile
