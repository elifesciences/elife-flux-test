# elife-flux-test
Declares the deploys to kubernetes-aws--flux-test cluster using fluxcd

## Useful commands

If flux is installed to a namespace `fluxctl` needs to be invoked as:

```
fluxctl --k8s-fwd-ns flux
```

__Observing state__
```sh
fluxctl sync  # forces flux to sync git repo
fluxctl list-workloads --all-namespaces
helm list --all-namespaces

# List all image versions running on cluster
kubectl get pods --all-namespaces -o=jsonpath='{range .items[*]}{"\n"}{.metadata.name}{":\t"}{range .spec.containers[*]}{.image}{", "}{end}{end}' |
sort | column -t
```

__Debugging__
```sh
kubectl -n flux logs helm-operator-86b8f67577-wldq5 --follow
helm -n adm history adm-prometheus-operator -o yaml
```

If `helm lint` is happy but operator is complaining:

- copy `values` section from the `HelmRelease` to a `dummy.yaml`
- run `helm dependency update charts/libero-reviewer`
- now you can run `helm install --dry-run` or `helm template --debug`


__helm-operator can't upgrade due to `failed` helm state__

In this case it appears one has to manually upgrade the helm chart. See [faq](https://docs.fluxcd.io/projects/helm-operator/en/stable/faq/#a-helmrelease-is-stuck-in-a-failed-release-state-how-do-i-force-it-through) and [this issue](https://github.com/fluxcd/helm-operator/issues/241#issuecomment-578351380).

```sh
helm -n <namespace> list
helm -n <namespace> -i <release> upgrade --reuse-values <any additional flags> <chart>
```

## Bootstrapping the cluster to use flux

This only needs to be done upon creation of the cluster.

This follows [flux get-started-helm](https://docs.fluxcd.io/en/stable/tutorials/get-started-helm/).

1. Configure your `kubectl` using your aws credentials.
   ```sh
   aws eks update-kubeconfig \
      --name kubernetes-aws--flux-test \
      --role arn:aws:iam::512686554592:role/kubernetes-aws--flux-test--AmazonEKSUserRole
   ```

2. Install flux and helm-operator on the cluster, link to this repo  
   NOTE: make sure to use `helm3`
   ```sh
   kubectl apply -f https://raw.githubusercontent.com/fluxcd/helm-operator/master/deploy/crds.yaml

   helm repo add fluxcd https://charts.fluxcd.io

   kubectl create namespace flux

   helm upgrade -i flux fluxcd/flux \
     --set git.url=git@github.com:elifesciences/elife-flux-test \
     --set syncGarbageCollection.enabled=true \
    --set prometheus.serviceMonitor.create=true \
    --set prometheus.serviceMonitor.namespace=adm \
     --namespace flux

   helm upgrade -i helm-operator fluxcd/helm-operator \
    --set git.ssh.secretName=flux-git-deploy \
    --set helm.versions=v3 \
    --set prometheus.serviceMonitor.create=true \
    --set prometheus.serviceMonitor.namespace=adm \
    --namespace flux
   ```

3. Add flux to repo's deploy keys
   ```sh
   fluxctl identity --k8s-fwd-ns flux
   # add this as deploy key with push rights to the github repo
   ```

4. Make kube-proxy metrics accessible to prometheus
   By default kube-proxy metrics are only accessible on localhost.  
   See prometheus operator (readme)[https://github.com/helm/charts/tree/master/stable/prometheus-operator#kubeproxy]

   - edit configmap `kubectl -n kube-system edit cm kube-proxy-config`
   - set `metricsBindAddress: 0.0.0.0:10249`
   - delete all `kube-proxy` pods, they will be recreated with the new config
