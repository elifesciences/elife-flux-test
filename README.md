The cluster linked to this repo is for testing changes to the infrastructure of the eLife [production k8s cluster](https://github.com/elifesciences/elife-flux-cluster).

The documentation from the production cluster applies.

Observability
=============

- [Kubernetes Dashboard](https://dashboard--test-cluster.elifesciences.org)
- [Grafana Dashboards](https://grafana--test-cluster.elifesciences.org)
- [Prometheus (Metrics)](https://prometheus--test-cluster.elifesciences.org)
- [Alertmanager](https://alertmanager--test-cluster.elifesciences.org)


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
