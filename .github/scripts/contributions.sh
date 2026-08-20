#!/usr/bin/env bash
# Regenerates the upstream-contributions badge block in README.md.
set -euo pipefail

USER=${1:-maryny4}
README=${2:-README.md}
START="<!-- contributions:start -->"
END="<!-- contributions:end -->"

esc() { printf '%s' "$1" | sed -e 's/_/__/g' -e 's/-/--/g' -e 's/ /_/g'; }

repos=$(gh api --paginate "search/issues?q=is:pr+is:merged+author:${USER}&per_page=100" --jq '.items[].repository_url' |
  sed 's|.*/repos/||' | grep -iv "^${USER}/" | sort | uniq -c | sort -rn | awk '{print $2, $1}')

block=""
while read -r repo count; do
  [ -n "$repo" ] || continue
  owner=${repo%%/*}
  name=${repo##*/}
  query="repo%3A${owner}%2F${name}+is%3Apr+is%3Amerged+author%3A${USER}"
  block+="[![${repo}](https://img.shields.io/badge/$(esc "$owner")-$(esc "$name")-24292f?style=flat-square&logo=github)](https://github.com/${repo})"
  block+=" [![merged PRs](https://img.shields.io/github/issues-search?query=${query}&label=merged%20PRs&color=2ea44f&style=flat-square)](https://github.com/${repo}/pulls?q=is%3Apr+author%3A${USER}+is%3Amerged)"
  block+=" [![stars](https://img.shields.io/github/stars/${repo}?style=flat-square&label=%E2%98%85&color=e3b341)](https://github.com/${repo}/stargazers)"
  block+=$'\n\n'
  echo "found ${repo} (${count} merged)" >&2
done <<< "$repos"

python3 - "$README" "$START" "$END" "$block" <<'PY'
import sys
path, start, end, block = sys.argv[1:5]
s = open(path).read()
i, j = s.index(start), s.index(end)
open(path, 'w').write(s[:i] + start + "\n\n" + block.strip() + "\n\n" + s[j:])
PY
