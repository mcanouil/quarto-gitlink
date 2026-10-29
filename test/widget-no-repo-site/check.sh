#!/usr/bin/env bash
# Render the site with no repository, with and without a widget placeholder,
# and count the warnings about the unresolved repository.
set -euo pipefail

site_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
warning="Widget is enabled but no repository could be resolved"
failures=0

# Stop git at the test directory, so the remote of this repository is not found.
GIT_CEILING_DIRECTORIES="$(dirname "${site_dir}")"
export GIT_CEILING_DIRECTORIES

count_warnings() {
	local log
	log="$(quarto render "${site_dir}" "$@" 2>&1)"
	{ grep -oF -- "${warning}" <<<"${log}" || true; } | wc -l | tr -d ' '
}

expect_warnings() {
	local label="${1}" wanted="${2}" found="${3}"
	if [[ "${found}" -eq "${wanted}" ]]; then
		printf '%-4s %s\n' "ok" "${label}"
	else
		printf '%-4s %s (found %s, wanted %s)\n' "FAIL" "${label}" "${found}" "${wanted}"
		failures=$((failures + 1))
	fi
}

expect_warnings "no placeholder, no warning" 0 "$(count_warnings)"
expect_warnings "placeholder, one warning per page" 2 "$(count_warnings --profile placeholder)"

if [[ "${failures}" -gt 0 ]]; then
	printf '\n%d check(s) failed.\n' "${failures}" >&2
	exit 1
fi

printf '\nAll checks passed.\n'
