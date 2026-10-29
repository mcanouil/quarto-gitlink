#!/usr/bin/env bash
# Render the page with the QUARTO_EXECUTE_INFO file damaged in each way the
# project metadata helper reports, and count the warnings gitlink logs.
set -euo pipefail

site_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
warning="Could not read the project metadata"
failures=0

expect_warnings() {
	local mode="${1}" wanted="${2}" reason="${3:-}" expected render_log found
	expected="${warning}"
	if [[ -n "${reason}" ]]; then
		expected="${warning} (${reason}) from '"
	fi
	rm -f "${site_dir}/index.html"
	render_log="$(quarto render "${site_dir}" -M "break-execute-info:${mode}" 2>&1)" || {
		printf '%s\n' "${render_log}" >&2
		exit 1
	}
	found="$(grep -cF -- "${expected}" <<<"${render_log}" || true)"
	if [[ "${found}" -eq "${wanted}" ]]; then
		printf '%-4s %s\n' "ok" "${mode}: ${wanted} warning(s)"
	else
		printf '%-4s %s (found %s, wanted %s)\n' "FAIL" "${mode}" "${found}" "${wanted}"
		failures=$((failures + 1))
	fi
	if ! grep -qF 'href="https://github.com/mcanouil/quarto-gitlink/issues/1"' "${site_dir}/index.html"; then
		printf '%-4s %s\n' "FAIL" "${mode}: reference #1 did not convert"
		failures=$((failures + 1))
	fi
}

expect_warnings none 0
expect_warnings unreadable 1 "file is unreadable"
expect_warnings empty 1 "file is empty"
expect_warnings invalid-json 1 "invalid JSON"
expect_warnings no-metadata 1 "no format.metadata table"

if [[ "${failures}" -gt 0 ]]; then
	printf '\n%d check(s) failed.\n' "${failures}" >&2
	exit 1
fi

printf '\nAll checks passed.\n'
