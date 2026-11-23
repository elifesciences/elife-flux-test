The cluster linked to this repo is for testing changes to the infrastructure of the eLife [production k8s cluster](https://github.com/elifesciences/elife-flux-cluster).

The documentation from the production cluster applies.

Observability
=============

- [Kubernetes Dashboard](https://dashboard--test-cluster.elifesciences.org)
- [Dash0](https://app.dash0.com) (metrics, logs, alerts and dashboards, select `flux-test` dataset in top left dropdown)


Overview of the Cluster
==========================

Use this git repo to control the cluster state (no `kubectl` or `helm`
cli action needed/wanted).

-   [Flux](https://docs.fluxcd.io) will try to apply any `yaml` file in
    this repo to the cluster

-   [HelmOperator](https://docs.fluxcd.io/projects/helm-operator) allows
    use of helm charts

-   folders have no meaning to cluster, are used to keep things tidy for
    us humans
