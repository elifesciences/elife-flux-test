#!/bin/bash
set -e

ENV_DEST_DIR='deployments/epp/previews'
ENV_NAME_PREFIX='epp-preview'
REPO='elifesciences/enhanced-preprints-server'
ORG='elifesciences'
KUSTOMIZATION_TEMPLATE='kustomizations/apps/epp/preview_template.yaml'

# First, remove all envs. They will be recreated, and there's no race issues because they will be in a single commit, which is atomic
rm $ENV_DEST_DIR/*.yaml || true

# now create all envs related to current open and labelled PRs
for pr in $(gh pr list --repo $REPO --label preview --json number,potentialMergeCommit,mergeable,author | jq -c '.[]'); do
    pr_mergable="$(echo $pr | jq .mergeable)"

    export author="$(echo $pr | jq -r .author.login)"
    export pr_id="$(echo $pr | jq .number)"
    export pr_commit="$(echo $pr | jq -r .potentialMergeCommit.oid)"

    export image_tag="preview-${pr_commit:0:8}"
    export deployment_name="$ENV_NAME_PREFIX-${pr_id}"
    export deployment_hostname="$deployment_name.elifesciences.org"

    if curl -qfL "https://api.github.com/orgs/${ORG}/members/${author}"; then
        echo "Creating env for PR $pr_id"

        envsubst < $KUSTOMIZATION_TEMPLATE > ${ENV_DEST_DIR}/${pr_id}.yaml

        # commenting across repos doesn't work without more permissions
        # pr_comment="Preview instance will be available at https://${deployment_hostname}/"
        # echo -n "check if we need to add comment about preview environment $pr_id..."
        # if gh -R $REPO pr view 309 --json comments | grep "$pr_comment" > /dev/null; then
        #     echo "already exists, skipping."
        # else
        #     echo "Adding comment..."
        #     gh pr comment $pr_id --repo "$REPO" --body "$pr_comment"
        # echo "Done"
        # fi
    else
        echo "Skipping PR with preview label when author ${author} isn't a member of ${ORG} org on github"
    fi
done

# now commit
# Done in script, so that if there is an error, the whole script exits (set -e), and nothing is committed.
git add $ENV_DEST_DIR
