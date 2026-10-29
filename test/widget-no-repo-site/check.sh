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

expect_warnings() {
	local label="${1}" wanted="${2}" render_log="${3}" found
	found="$(grep -cF -- "${warning}" <<<"${render_log}" || true)"
	if [[ "${found}" -eq "${wanted}" ]]; then
		printf '%-4s %s\n' "ok" "${label}"
	else
		printf '%-4s %s (found %s, wanted %s)\n' "FAIL" "${label}" "${found}" "${wanted}"
		failures=$((failures + 1))
	fi
}

render_log="$(quarto render "${site_dir}" 2>&1)" || {
	printf '%s\n' "${render_log}" >&2
	exit 1
}
expect_warnings "no placeholder, no warning" 0 "${render_log}"

render_log="$(quarto render "${site_dir}" --profile placeholder 2>&1)" || {
	printf '%s\n' "${render_log}" >&2
	exit 1
}
expect_warnings "placeholder, one warning per page" 2 "${render_log}"

render_log="$(quarto render "${site_dir}" --profile bare 2>&1)" || {
	printf '%s\n' "${render_log}" >&2
	exit 1
}
expect_warnings "bare-string placeholder, one warning per page" 2 "${render_log}"

if [[ "${failures}" -gt 0 ]]; then
	printf '\n%d check(s) failed.\n' "${failures}" >&2
	exit 1
fi

printf '\nAll checks passed.\n'
