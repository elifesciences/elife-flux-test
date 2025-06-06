#!/usr/bin/env bash

# This script downloads the Flux OpenAPI schemas, then it validates the
# Flux custom resources and the kustomize overlays using kubeconform.
# This script is meant to be run locally and in CI before the changes
# are merged on the main branch that's synced by Flux.

# Copyright 2020 The Flux authors. All rights reserved.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

# This script is meant to be run locally and in CI to validate the Kubernetes
# manifests (including Flux custom resources) before changes are merged into
# the branch synced by Flux in-cluster.

# Prerequisites
# - yq v4.6
# - kustomize v4.1
# - kubeconform v0.4.12


## Set up Additional Environment variables that need values for clusters
export ts="test"
export env="test"
export hostname="test"

# Settings for various tool calls
#
kubeconform_config="-strict -ignore-missing-schemas -schema-location /tmp/crd-schemas/flux/master-standalone-strict/ -schema-location /tmp/crd-schemas/kubernetes-json-schema/master-standalone-strict/ -verbose -skip Canary,HelmRelease"
# mirror kustomize-controller build options
kustomize_flags="--load-restrictor=LoadRestrictionsNone"
kustomize_config="kustomization.yaml"


echo "# INFO - Validating yaml files are valid YAML"
# find . -type f -name '*.yaml' -print0 | while IFS= read -r -d $'\0' file;
#   do
#     echo "## INFO - Validating yaml $file"
#     yq e 'true' "$file" > /dev/null
# done
# echo ""

echo "# INFO - Downloading Flux OpenAPI schemas"
rm -Rf /tmp/crd-schemas
mkdir -p /tmp/crd-schemas/flux/master-standalone-strict
curl -sL https://github.com/fluxcd/flux2/releases/latest/download/crd-schemas.tar.gz | tar zxf - -C /tmp/crd-schemas/flux/master-standalone-strict

echo "# INFO - Checking out kubernetes OpenAPI schemas from yannh/kubernetes-json-schema"
git -C /tmp/crd-schemas/ clone --depth 1  --filter=blob:none  --no-checkout https://github.com/yannh/kubernetes-json-schema
git -C /tmp/crd-schemas/kubernetes-json-schema sparse-checkout set master-standalone-strict
git -C /tmp/crd-schemas/kubernetes-json-schema checkout

echo "# INFO - Validating clusters is conforming to flux schema (excluding patches)"
find ./clusters -type f -name '*.yaml' -not -path "./clusters/**/patches/*" -print0 | while IFS= read -r -d $'\0' file;
  do
    echo "## INFO - Validating cluster file ${file}"
    conform_output=$(kubeconform $kubeconform_config ${file})
    if [[ ${PIPESTATUS[0]} != 0 ]]; then
      echo "## ERROR ${file} cause a kubeconform error"
      echo $conform_output
      exit 1
    fi
done


echo "# INFO - Validating kustomize overlays (excluding ./clusters path)"
find . -type f -name $kustomize_config -not -path "./clusters/*" -print0 | while IFS= read -r -d $'\0' file;
  do
    echo "## INFO - Validating kustomization ${file/%$kustomize_config}"
    tmp_dir=$(mktemp -d)

    kustomize build "${file/%$kustomize_config}" $kustomize_flags > $tmp_dir/kustomize_output 2> $tmp_dir/kustomize_error
    if [[ $? != 0 ]]; then
      echo "## ERROR ${file/%$kustomize_config} failed kustomize build"
      cat $tmp_dir/kustomize_error
      cat $tmp_dir/kustomize_output
      rm -Rf $tmp_dir
      exit 1
    fi

    cat $tmp_dir/kustomize_output | kubeconform $kubeconform_config > $tmp_dir/kubeconform_output 2> $tmp_dir/kubeconform_error
    if [[ ${PIPESTATUS[1]} != 0 ]]; then
      echo "## INFO ${file/%$kustomize_config} failed kubeconform"
      if [[ $ACTIONS_STEP_DEBUG == "true" ]]; then
        echo "## DEBUG ${file/%$kustomize_config} kubeconform_error:"
        cat "$tmp_dir/kubeconform_error"
        echo "## DEBUG ${file/%$kustomize_config} kubeconform_output:"
        cat "$tmp_dir/kubeconform_output"
      fi
      echo "## INFO trying with envsubst"
      cat $tmp_dir/kustomize_output | flux envsubst --strict > $tmp_dir/envsubst_output 2> $tmp_dir/envsubst_error
      if [[ ${PIPESTATUS[1]} != 0 ]]; then
        echo "## ERROR ${file/%$kustomize_config} failed envsubst"
        cat $tmp_dir/envsubst_error
        cat $tmp_dir/envsubst_output
        rm -Rf $tmp_dir
        exit 1
      fi

      cat $tmp_dir/envsubst_output | kubeconform $kubeconform_config > $tmp_dir/kubeconform_output 2> $tmp_dir/kubeconform_error
      if [[ ${PIPESTATUS[1]} != 0 ]]; then
        echo "## ERROR ${file/%$kustomize_config} failed kubeconform"
        cat $tmp_dir/kubeconform_error
        cat $tmp_dir/kubeconform_output
        rm -Rf $tmp_dir
        exit 1
      fi
    fi

    rm -Rf $tmp_dir
done
