#!/bin/bash
set -e

ENV_DEST_DIR='deployments/epp/previews'
REPO='elifesciences/enhanced-preprints-server'
KUSTOMIZATION_TEMPLATE='kustomizations/apps/epp/preview_template.yaml'

# First, remove all envs. They will be recreated, and there's no race issues because they will be in a single commit, which is atomic
rm $ENV_DEST_DIR/*.yaml || true

# now create all envs related to current open and labelled PRs
for pr in $(gh pr list --repo $REPO --label preview --json number,potentialMergeCommit,mergeable | jq -c '.[]'); do
    pr_mergable="$(echo $pr | jq .mergeable)"

    export pr_id="$(echo $pr | jq .number)"
    export pr_commit="$(echo $pr | jq -r .potentialMergeCommit.oid)"
    export image_tag="preview-${pr_commit:0:8}"

    echo "Creating env for PR $pr_id"

    envsubst < $KUSTOMIZATION_TEMPLATE > ${ENV_DEST_DIR}/${pr_id}.yaml
done

# now commit
# Done in script, so that if there is an error, the whole script exits (set -e), and nothing is committed.
git add $ENV_DEST_DIR
