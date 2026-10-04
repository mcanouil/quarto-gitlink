#!/usr/bin/env bash
# Render the badge test site and check the colours each badge is drawn in.
set -euo pipefail

site_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
render_log="$(quarto render "${site_dir}" 2>&1)"

failures=0

report() {
	local status="${1}" label="${2}"
	printf '%-4s %s\n' "${status}" "${label}"
	if [[ "${status}" == "FAIL" ]]; then
		failures=$((failures + 1))
	fi
}

expect_badge() {
	local label="${1}" page="${2}" style="${3}"
	local file="${site_dir}/_site/${page}.html"
	if [[ -f "${file}" ]] && grep -qF -- "style=\"${style}\"" "${file}"; then
		report "ok" "${label}"
	else
		report "FAIL" "${label}"
	fi
}

expect_absent() {
	local label="${1}" text="${2}"
	if grep -rqF --include='*.html' -- "${text}" "${site_dir}/_site"; then
		report "FAIL" "${label}"
	else
		report "ok" "${label}"
	fi
}

expect_log() {
	local label="${1}" text="${2}"
	if grep -qF -- "${text}" <<<"${render_log}"; then
		report "ok" "${label}"
	else
		report "FAIL" "${label}"
	fi
}

expect_log_absent() {
	local label="${1}" text="${2}"
	if grep -qF -- "${text}" <<<"${render_log}"; then
		report "FAIL" "${label}"
	else
		report "ok" "${label}"
	fi
}

expect_badge "default background takes black text" "index" \
	'background-color: #c3c3c3; color: #000000;'
expect_badge "dark background takes white text" "dark" \
	'background-color: #003366; color: #ffffff;'
expect_badge "named background takes white text" "named" \
	'background-color: navy; color: #ffffff;'
expect_badge "explicit text colour wins" "explicit" \
	'background-color: #003366; color: #ffcc00;'
expect_badge "five-digit hex falls back to the default" "odd-hex" \
	'background-color: #c3c3c3; color: #000000;'
expect_badge "invalid custom platforms keep the default colours" "bad-platforms" \
	'background-color: #c3c3c3; color: #000000;'
expect_badge "background below the boundary takes white text" "boundary-white" \
	'background-color: #757575; color: #ffffff;'
expect_badge "background above the boundary takes black text" "boundary-black" \
	'background-color: #767676; color: #000000;'
expect_badge "named text colour is used as given" "named-text" \
	'background-color: #003366; color: white;'
expect_badge "US spelling of both options" "us-spelling" \
	'background-color: #003366; color: #ffcc00;'
expect_badge "colour that is not a string falls back" "boolean-colour" \
	'background-color: #c3c3c3; color: #000000;'
expect_badge "translucent dark background takes white text" "translucent" \
	'background-color: #003366cc; color: #ffffff;'
expect_badge "faint background takes the better text colour" "faint" \
	'background-color: #00000040; color: #ffffff;'
expect_badge "half-transparent grey takes the better worst case" "half-grey" \
	'background-color: #78787880; color: #ffffff;'
expect_log "faint background warns" "'#00000040' is too transparent"
expect_log_absent "translucent background does not warn" "'#003366cc' is too transparent"
expect_absent "no Bootstrap colour class on the badge" 'text-bg-secondary'

typst_file="${site_dir}/typst.typ"
if [[ -f "${typst_file}" ]] && grep -qF -- 'fill: rgb("#003366")' "${typst_file}" &&
	grep -qF -- 'fill: rgb("#FFFFFF")' "${typst_file}"; then
	report "ok" "Typst badge converts a named text colour to hex"
else
	report "FAIL" "Typst badge converts a named text colour to hex"
fi

if [[ "${failures}" -gt 0 ]]; then
	printf '\n%d check(s) failed.\n' "${failures}" >&2
	exit 1
fi

printf '\nAll checks passed.\n'
