#!/usr/bin/env bash
# Checks the security headers for cv.hirepotential.co.uk. GitHub Pages ignores upstream's
# public/_headers, so the same headers are set by a Cloudflare rule (see FORK.md). This fails if
#   1. upstream has changed the headers in its _headers file since our rule was copied from it
#      (.github/headers/upstream-snapshot.txt), or
#   2. the live site isn't sending exactly what our rule sets (.github/headers/cloudflare-rule.txt).
# Usage: check.sh <path to upstream's public/_headers> [site URL]
set -uo pipefail

HERE="$(cd "$(dirname "$0")" && pwd)"
HEADERS_FILE="$1"
SITE="${2:-https://cv.hirepotential.co.uk}"
NAMES='content-security-policy|x-content-type-options|x-frame-options|referrer-policy|permissions-policy|cross-origin-opener-policy|cross-origin-resource-policy|strict-transport-security'
SUMMARY="${GITHUB_STEP_SUMMARY:-/dev/stdout}"
status=0

# "Name: value" lines, name lower-cased, whitespace tidied, sorted.
normalise() {
  sed -E 's/\r$//; s/^[[:space:]]+//; s/[[:space:]]+$//' |
    awk 'NF { i = index($0, ":"); printf "%s: %s\n", tolower(substr($0, 1, i - 1)), substr($0, i + 2) }' |
    grep -E "^(${NAMES}): " | sort
}

# Upstream's headers for every route: the indented lines under "/*".
current_upstream=$(awk '/^\/\*$/ { f = 1; next } f && /^[^[:space:]]/ { f = 0 } f' "$HEADERS_FILE" | normalise)
snapshot=$(normalise < "$HERE/upstream-snapshot.txt")
expected_live=$(normalise < "$HERE/cloudflare-rule.txt")
live=$(curl -sSI --max-time 20 "$SITE/?headers-check=$(date +%s)" | normalise)

{
  echo "### Security headers"
  if [ "$current_upstream" = "$snapshot" ]; then
    echo "- Upstream's headers are unchanged since our Cloudflare rule was copied from them."
  else
    status=1
    echo "- :warning: **Upstream has changed its headers.** Update the Cloudflare rule to match (keeping HSTS without \`includeSubDomains; preload\`), then update \`.github/headers/upstream-snapshot.txt\` and \`cloudflare-rule.txt\`."
    echo '```diff'
    diff <(echo "$snapshot") <(echo "$current_upstream") | grep -E '^[<>]' | sed 's/^</-/; s/^>/+/'
    echo '```'
  fi
  if [ "$live" = "$expected_live" ]; then
    echo "- The live site sends exactly what our Cloudflare rule sets."
  else
    status=1
    echo "- :warning: **The live site's headers don't match our Cloudflare rule** (rule changed or removed?)."
    echo '```diff'
    diff <(echo "$expected_live") <(echo "$live") | grep -E '^[<>]' | sed 's/^</-/; s/^>/+/'
    echo '```'
  fi
} >> "$SUMMARY"

[ "$status" -eq 0 ] || echo "::error::Security headers need attention. See the run summary."
exit "$status"
