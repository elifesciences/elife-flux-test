#!/bin/bash

# As script to update these manually

if [ -z "$1" ]; then
    echo 'ERROR: specify a prometheus-operator git reference to get the CRDs'
    echo "e.g. \`$0 0.2.14\`"
    exit 1
fi

cd $(dirname $0)

curl -O https://raw.githubusercontent.com/grafana/helm-charts/grafana-agent-operator-$1/charts/agent-operator/crds/monitoring.coreos.com_podmonitors.yaml
curl -O https://raw.githubusercontent.com/grafana/helm-charts/grafana-agent-operator-$1/charts/agent-operator/crds/monitoring.coreos.com_probes.yaml
curl -O https://raw.githubusercontent.com/grafana/helm-charts/grafana-agent-operator-$1/charts/agent-operator/crds/monitoring.coreos.com_servicemonitors.yaml
curl -O https://raw.githubusercontent.com/grafana/helm-charts/grafana-agent-operator-$1/charts/agent-operator/crds/monitoring.grafana.com_grafanaagents.yaml
curl -O https://raw.githubusercontent.com/grafana/helm-charts/grafana-agent-operator-$1/charts/agent-operator/crds/monitoring.grafana.com_integrations.yaml
curl -O https://raw.githubusercontent.com/grafana/helm-charts/grafana-agent-operator-$1/charts/agent-operator/crds/monitoring.grafana.com_logsinstances.yaml
curl -O https://raw.githubusercontent.com/grafana/helm-charts/grafana-agent-operator-$1/charts/agent-operator/crds/monitoring.grafana.com_metricsinstances.yaml
curl -O https://raw.githubusercontent.com/grafana/helm-charts/grafana-agent-operator-$1/charts/agent-operator/crds/monitoring.grafana.com_podlogs.yaml
