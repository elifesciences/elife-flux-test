#!/bin/bash
set -e

ENV_DEST_DIR='deployments/epp/previews'
ENV_NAME_PREFIX='epp-preview'
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
    export deployment_name="$ENV_NAME_PREFIX-${pr_id}"
    export deployment_hostname="$deployment_name.elifesciences.org"

    echo "Creating env for PR $pr_id"

    envsubst < $KUSTOMIZATION_TEMPLATE > ${ENV_DEST_DIR}/${pr_id}.yaml

    pr_comment="Preview instance will be available at https://${deployment_hostname}/"
    echo -n "check if we need to append preview environment to PR body $pr_id..."
    pr_body=$(gh -R $REPO pr view 309 --json body | jq -r .body);
    if echo $pr_body | grep "$pr_comment" > /dev/null; then
        echo "already exists, skipping."
    else
        echo "Adding to end of PR body..."
        gh pr edit $pr_id --repo "$REPO" --body-file - << GHBODY
$pr_body

---
Preview instance will be available at https://${deployment_hostname}/
GHBODY
    echo "Done"
    fi
done

# now commit
# Done in script, so that if there is an error, the whole script exits (set -e), and nothing is committed.
git add $ENV_DEST_DIR
