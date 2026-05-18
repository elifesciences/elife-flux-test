#!/bin/bash

set -euo pipefail

# A script to update these manually

cd $(dirname $0)

helm repo add traefik https://traefik.github.io/charts
helm repo update
helm show crds traefik/traefik >traefik.crd.yaml
