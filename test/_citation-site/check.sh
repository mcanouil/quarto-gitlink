#!/usr/bin/env bash
# Render the citation test site and check that bibliography citations stay
# citations while Git hosting mentions become links.
set -euo pipefail

site_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
render_log="$(quarto render "${site_dir}" 2>&1)" || {
	printf '%s\n' "${render_log}" >&2
	exit 1
}

failures=0

report() {
	local status="${1}" label="${2}"
	printf '%-4s %s\n' "${status}" "${label}"
	if [[ "${status}" == "FAIL" ]]; then
		failures=$((failures + 1))
	fi
}

expect_in() {
	local label="${1}" file="${site_dir}/${2}" text="${3}"
	if [[ -f "${file}" ]] && grep -qF -- "${text}" "${file}"; then
		report "ok" "${label}"
	else
		report "FAIL" "${label}"
	fi
}

expect_not_in() {
	local label="${1}" file="${site_dir}/${2}" text="${3}"
	if [[ -f "${file}" ]] && ! grep -qF -- "${text}" "${file}"; then
		report "ok" "${label}"
	else
		report "FAIL" "${label}"
	fi
}

html="sub/index.html"
expect_in "HTML: citation with an underscore stays a citation" "${html}" "Canouil et al., 2020"
expect_in "HTML: cited reference is in the reference list" "${html}" 'id="ref-canouil_nacho_2020"'
expect_not_in "HTML: citation is not turned into a user link" "${html}" 'href="https://github.com/canouil"'
expect_in "HTML: user mention becomes a link" "${html}" 'href="https://github.com/mcanouil"'
expect_in "HTML: id listed in mentions becomes a link" "${html}" 'href="https://github.com/jdoe"'
expect_not_in "HTML: id listed in mentions is not in the reference list" "${html}" 'id="ref-jdoe"'

tex="sub/index.tex"
expect_in "LaTeX: citation with an underscore stays a citation" "${tex}" "Canouil et al., 2020"
expect_not_in "LaTeX: citation is not turned into a user link" "${tex}" '{https://github.com/canouil}'
expect_in "LaTeX: user mention becomes a link" "${tex}" '{https://github.com/mcanouil}'
expect_in "LaTeX: id listed in mentions becomes a link" "${tex}" '{https://github.com/jdoe}'

typ="typst.typ"
expect_in "Typst: citation with an underscore stays a citation" "${typ}" "@canouil_nacho_2020"
expect_not_in "Typst: citation is not turned into a user link" "${typ}" '"https://github.com/canouil"'
expect_in "Typst: user mention becomes a link" "${typ}" '"https://github.com/mcanouil"'
expect_in "Typst: id listed in mentions becomes a link" "${typ}" '"https://github.com/jdoe"'

typ_root="typst-root.typ"
expect_in "Typst, path from the project root: citation stays a citation" "${typ_root}" "@canouil_nacho_2020"
expect_not_in "Typst, path from the project root: citation is not turned into a user link" "${typ_root}" '"https://github.com/canouil"'
expect_in "Typst, path from the project root: user mention becomes a link" "${typ_root}" '"https://github.com/mcanouil"'

if [[ "${failures}" -gt 0 ]]; then
	printf '\n%d check(s) failed.\n' "${failures}" >&2
	exit 1
fi

printf '\nAll checks passed.\n'
