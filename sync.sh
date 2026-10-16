#!/usr/bin/env bash
# Puts stub.yml at .github/workflows/claude.yml in every non-fork, non-archived repo of the owner
# and copies the Claude tokens into each repo's secrets. Repos with the topic "no-claude" are skipped.
# Usage: GH_TOKEN=<sync PAT> PRO=<pro token> TEAM=<team token> ./sync.sh    (DRY=1 only prints)
set -uo pipefail
cd "$(dirname "$0")"

owner=${GITHUB_REPOSITORY_OWNER:-puIad}
path=.github/workflows/claude.yml
want=$(git hash-object stub.yml)
content=$(base64 -w0 stub.yml)
run() { if [ -n "${DRY:-}" ]; then echo "  would: ${*:1:4}"; else "$@"; fi; }
fail=0

repos=$(gh repo list "$owner" --source --no-archived --limit 1000 \
  --json nameWithOwner,isEmpty,repositoryTopics \
  --jq '.[] | select(.isEmpty | not) | select([.repositoryTopics[]?.name] | index("no-claude") | not) | .nameWithOwner') || exit 1
[ -n "$repos" ] || { echo "no repos visible to the token"; exit 1; }

for repo in $repos; do
  echo "$repo"
  if [ -n "${PRO:-}" ]; then printf %s "$PRO" | run gh secret set CLAUDE_CODE_OAUTH_TOKEN -R "$repo" || fail=1; fi
  if [ -n "${TEAM:-}" ]; then printf %s "$TEAM" | run gh secret set CLAUDE_CODE_OAUTH_TOKEN_TEAM -R "$repo" || fail=1; fi
  have=$(gh api "repos/$repo/contents/$path" --jq .sha 2>/dev/null) || have=""
  if [ -z "$have" ]; then
    run gh api -X PUT "repos/$repo/contents/$path" --silent \
      -f message="Add Claude workflow [skip ci]" -f content="$content" || fail=1
  elif [ "$have" != "$want" ]; then
    run gh api -X PUT "repos/$repo/contents/$path" --silent \
      -f message="Update Claude workflow [skip ci]" -f content="$content" -f sha="$have" || fail=1
  fi
done
exit $fail
