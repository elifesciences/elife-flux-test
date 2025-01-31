#!/bin/bash

# As script to update these manually

if [ -z "$1" ]; then
    echo 'ERROR: specify a keda release version to get the CRDs'
    echo "e.g. \`$0 0.2.0\`"
    exit 1
fi

cd $(dirname $0)

curl -sLO https://raw.githubusercontent.com/kro-run/kro/refs/tags/v$1/helm/crds/kro.run_resourcegraphdefinitions.yaml
