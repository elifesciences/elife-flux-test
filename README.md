# elife-flux-test
Declares the deploys to kubernetes-aws--flux-test cluster using fluxcd

## Useful commands

```sh
fluxctl list-workloads --all-namespaces
helm list --all-namespaces
fluxctl sync  # forces flux to sync git repo

# List all image versions running on cluster
kubectl get pods --all-namespaces -o=jsonpath='{range .items[*]}{"\n"}{.metadata.name}{":\t"}{range .spec.containers[*]}{.image}{", "}{end}{end}' |
sort | column -t
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
     --namespace flux

   helm upgrade -i helm-operator fluxcd/helm-operator \
    --set git.ssh.secretName=flux-git-deploy \
    --set helm.versions=v3 \
    --namespace flux
   ```

3. Add flux to repo's deploy keys
   ```sh
   fluxctl identity --k8s-fwd-ns flux
   # add this as deploy key with push rights to the github repo
   ```