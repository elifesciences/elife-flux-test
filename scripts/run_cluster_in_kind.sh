#!/bin/bash
set -e

# comment this line to run commands, uncomment to echo them
# DEBUG="echo "

$DEBUG kind delete cluster --name "elife-flux-test"
$DEBUG kind create cluster --name "elife-flux-test" --image=kindest/node:v1.25.8 --wait 30s

# install kwok into cluster
$DEBUG kubectl kustomize scripts/kwok/deploy_config | kubectl apply -f -
$DEBUG kubectl wait deployment -n kube-system kwok-controller --timeout=30s --for condition=Available=True

# Install Flux with toleration to run controllers on the real node
$DEBUG kubectl create ns flux
# make sure flux components get installed, with additional components
$DEBUG flux install --components-extra="image-reflector-controller,image-automation-controller" --toleration-keys=realnode

# taint the current node to not schedule workloads by default
$DEBUG kubectl taint node elife-flux-test-control-plane realnode=true:NoSchedule
# Install kwok nodes to run "workloads" on
$DEBUG kubectl apply -f scripts/kwok/1_large_simulated_node.yaml



# Install cluster stuff and wait
$DEBUG flux create source git flux-system --url=https://github.com/elifesciences/elife-flux-test --branch=master
$DEBUG flux create kustomization flux-system --source=flux-system --path=./clusters/end-to-end-tests
$DEBUG kubectl wait kustomizations.kustomize.toolkit.fluxcd.io --for=condition=ready --timeout=10m -n flux-system crds
$DEBUG kubectl wait kustomizations.kustomize.toolkit.fluxcd.io --for=condition=ready --timeout=10m -n flux-system system
$DEBUG kubectl wait kustomizations.kustomize.toolkit.fluxcd.io --for=condition=ready --timeout=10m -n flux-system deployments

$DEBUG kubectl wait helmreleases.helm.toolkit.fluxcd.io --for=condition=ready --timeout=5m -n autoscaler         cluster-autoscaler
$DEBUG kubectl wait helmreleases.helm.toolkit.fluxcd.io --for=condition=ready --timeout=5m -n infra             sealed-secrets
$DEBUG kubectl wait helmreleases.helm.toolkit.fluxcd.io --for=condition=ready --timeout=5m -n infra              ingress-nginx
$DEBUG kubectl wait helmreleases.helm.toolkit.fluxcd.io --for=condition=ready --timeout=5m -n infra              cert-manager
$DEBUG kubectl wait helmreleases.helm.toolkit.fluxcd.io --for=condition=ready --timeout=5m -n infra              external-dns
$DEBUG kubectl wait helmreleases.helm.toolkit.fluxcd.io --for=condition=ready --timeout=5m -n infra              oauth2-proxy
$DEBUG kubectl wait helmreleases.helm.toolkit.fluxcd.io --for=condition=ready --timeout=5m -n kube-system        descheduler
$DEBUG kubectl wait helmreleases.helm.toolkit.fluxcd.io --for=condition=ready --timeout=5m -n monitoring         metrics-server
# $DEBUG kubectl wait helmreleases.helm.toolkit.fluxcd.io --for=condition=ready --timeout=5m -n monitoring         gitops-dashboard
$DEBUG kubectl wait helmreleases.helm.toolkit.fluxcd.io --for=condition=ready --timeout=5m -n logging            loki-stack
$DEBUG kubectl wait helmreleases.helm.toolkit.fluxcd.io --for=condition=ready --timeout=5m -n crossplane-system  crossplane
$DEBUG kubectl wait helmreleases.helm.toolkit.fluxcd.io --for=condition=ready --timeout=5m -n db-operator-system psmdb-operator
$DEBUG kubectl wait helmreleases.helm.toolkit.fluxcd.io --for=condition=ready --timeout=10m -n monitoring         prometheus-stack


# if a param is specified, update the flux-system source branch to that
if [ ! -z "$1"  ] && git rev-parse --verify $1; then
    $DEBUG echo "About to do a sync from master to $1 branch. "

    $DEBUG flux create source git flux-system   --url=https://github.com/elifesciences/elife-flux-test   --branch=$1
    $DEBUG flux reconcile source git flux-system
fi;
