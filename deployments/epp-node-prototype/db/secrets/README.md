# Data-hub secrets

This file documents each secret in data-hub, and how to regenerate if necessary.

Each secret will need at least:
- [`kubectl`](https://kubernetes.io/docs/tasks/tools/) (to generate the secret)
- [`kubeseal`](https://github.com/bitnami-labs/sealed-secrets/releases) (to encrypt it).

The example commands will be run from the root of a checkout of this repository. In general, they will follow the same procedure:
1. create a secret file
2. create a sealed secret
3. remove the secret file

You will need to commit the sealed secret file, and create a PR and merge to the repo to update the credentials in the cluster.
Data-hub will need restarting to start using the new credentials.

# `epp-db-couchdb.yaml`

## Description
This secret contains the admin user/password and secrets used for cluster communication.

## Regenerate
```
COUCHDB_ERLANG_COOKIE="<erlangcookiehere>"
COUCHDB_PASSWORD="<adminpassword>"
COUCHDB_SECRET="<erlangsecrethere>"


kubectl create secret generic --dry-run=client epp-db-couchdb --namespace epp --from-literal=adminUsername=admin --from-literal=adminPassword=${COUCHDB_PASSWORD} --from-literal=cookieAuthSecret=${COUCHDB_SECRET} --from-literal=erlangCookie=${COUCHDB_ERLANG_COOKIE}  -o yaml >deployments/epp-node-prototype/db/secrets/epp-db-couchdb-unsealed.yaml
kubeseal --cert ./kubeseal-public.pem --format=yaml -f deployments/epp-node-prototype/db/secrets/epp-db-couchdb-unsealed.yaml > deployments/epp-node-prototype/db/secrets/epp-db-couchdb.yaml
rm deployments/epp-node-prototype/db/secrets/epp-db-couchdb-unsealed.yaml
```
