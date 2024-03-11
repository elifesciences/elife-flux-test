#!/bin/bash

# As script to update these manually

if [ -z "$1" ]; then
    echo 'ERROR: specify a clickhouse-operator version to get the CRDs'
    echo "e.g. \`$0 0.23.3\`"
    exit 1
fi

cd $(dirname $0)

curl -LO https://github.com/Altinity/clickhouse-operator/raw/release-$1/deploy/helm/crds/CustomResourceDefinition-clickhouseinstallations.clickhouse.altinity.com.yaml
curl -LO https://github.com/Altinity/clickhouse-operator/raw/release-$1/deploy/helm/crds/CustomResourceDefinition-clickhouseinstallationtemplates.clickhouse.altinity.com.yaml
curl -LO https://github.com/Altinity/clickhouse-operator/raw/release-$1/deploy/helm/crds/CustomResourceDefinition-clickhouseoperatorconfigurations.clickhouse.altinity.com.yaml
