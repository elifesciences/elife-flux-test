# Uprade EKS and worker nodes

AWS EKS doesn't update the cluster automatically.

## Resources

https://docs.aws.amazon.com/eks/latest/userguide/update-cluster.html

## Notes

- Changing api versions in the chart can lead to helm complaining about `existing resource conflict`. This appears to be an issue with helm3 that helm-operator [is aware of](https://github.com/fluxcd/helm-operator/issues/249) but can't fix until helm3 fixes it upstream.
- Cluster is set up via builder so you need to bump version in the [elife.yaml](https://github.com/elifesciences/builder/blob/master/projects/elife.yaml)
- Rolling out an updated AMI (e.g. security fix):
  - unclear how builder can do this as we only specify the k8s version, not the AMI
  - if we use managed nodes we can update via `eksctl` or the aws console (see [docs](https://docs.aws.amazon.com/eks/latest/userguide/update-managed-node-group.html))