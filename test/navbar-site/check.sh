#!/usr/bin/env bash
# Render the navbar test site and check what the filter must and must not touch.
set -euo pipefail

site_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
quarto render "${site_dir}" >/dev/null

index="${site_dir}/_site/index.html"
about="${site_dir}/_site/about.html"
failures=0

report() {
	local status="${1}" label="${2}"
	printf '%-4s %s\n' "${status}" "${label}"
	if [[ "${status}" == "FAIL" ]]; then
		failures=$((failures + 1))
	fi
}

expect_present() {
	local label="${1}" file="${2}" text="${3}"
	if grep -qF -- "${text}" "${file}"; then
		report "ok" "${label}"
	else
		report "FAIL" "${label}"
	fi
}

expect_absent() {
	local label="${1}" file="${2}" text="${3}"
	if grep -qF -- "${text}" "${file}"; then
		report "FAIL" "${label}"
	else
		report "ok" "${label}"
	fi
}

expect_count() {
	local label="${1}" file="${2}" text="${3}" wanted="${4}" found
	found="$(grep -coF -- "${text}" "${file}" || true)"
	if [[ "${found}" -ge "${wanted}" ]]; then
		report "ok" "${label}"
	else
		report "FAIL" "${label} (found ${found}, wanted at least ${wanted})"
	fi
}

# Targets that go through an inline markdown-pipeline entry keep their URL.
expect_present "navbar item href" "${index}" \
	'<a class="nav-link" href="https://github.com/mcanouil">'
expect_present "navbar tool href" "${index}" \
	'href="https://github.com/mcanouil" title="GitHub" class="quarto-navigation-tool'
expect_present "about link href" "${about}" \
	'<a href="https://github.com/mcanouil" class="about-link"'
expect_present "og:description stays plain" "${about}" \
	'property="og:description" content="A description that holds a reference to #1, which Quarto puts in a meta tag."'
expect_absent "no link text used as a target" "${index}" 'href="@'
expect_absent "no link text used as a target" "${about}" 'href="@'

# Body content and block entries still convert.
expect_count "body and footer references convert" "${index}" \
	'href="https://github.com/mcanouil/quarto-gitlink/issues/1"' 2
expect_present "reference converts on the about page" "${about}" \
	'href="https://github.com/mcanouil/quarto-gitlink/issues/1"'

# Known cost: a navigation entry text shares its envelope with the href.
expect_present "navbar item text stays plain" "${index}" \
	'<span class="menu-text">Issue #1</span>'

if [[ "${failures}" -gt 0 ]]; then
	printf '\n%d check(s) failed.\n' "${failures}" >&2
	exit 1
fi

printf '\nAll checks passed.\n'
