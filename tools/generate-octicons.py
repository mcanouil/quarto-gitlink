#!/usr/bin/env python3
# Gitlink - Octicon Registry Generator
# Builds _extensions/gitlink/octicons.json from the @primer/octicons npm
# package: every 16px icon body, plus the widget's friendly aliases and its
# custom marketplace icon. The Lua filter embeds only the icons a page's menu
# actually uses into the widget configuration.
#
# @license MIT
# @copyright 2026 Mickaël Canouil
# @author Mickaël Canouil

import json
import pathlib
import sys
import urllib.request

DATA_URL = "https://unpkg.com/@primer/octicons/build/data.json"

ALIASES = {
    "issue": "issue-opened",
    "pull-request": "git-pull-request",
    "release": "tag",
    "fork": "repo-forked",
    "discussion": "comment-discussion",
}

MARKETPLACE = (
    '<path d="M2 3.75C2 2.784 2.784 2 3.75 2h.5C5.216 2 6 2.784 6 3.75v1.5c0 '
    ".078-.005.155-.015.23A1.75 1.75 0 017 5.25V3.75C7 2.784 7.784 2 8.75 "
    "2h.5c.966 0 1.75.784 1.75 1.75v1.5c0 .078-.005.155-.015.23A1.75 1.75 0 "
    "0112 5.25v-1.5C12 2.784 12.784 2 13.75 2h.5c.966 0 1.75.784 1.75 "
    "1.75v8.5A1.75 1.75 0 0114.25 14h-.5A1.75 1.75 0 0112 12.25v-1.5c0-.078."
    "005-.155.015-.23A1.75 1.75 0 0111 10.75v1.5c0 .966-.784 1.75-1.75 "
    "1.75h-.5A1.75 1.75 0 016 12.25v-1.5c0-.078.005-.155.015-.23A1.75 1.75 0 "
    '015 10.75v1.5c0 .966-.784 1.75-1.75 1.75h-.5A1.75 1.75 0 011 12.25v-8.5z"/>'
)


def main() -> None:
    try:
        with urllib.request.urlopen(DATA_URL, timeout=30) as response:
            data = json.load(response)
    except (OSError, json.JSONDecodeError) as error:
        sys.exit(f"Failed to fetch or parse {DATA_URL}: {error}")

    icons: dict[str, str] = {}
    for name, spec in data.items():
        height = spec.get("heights", {}).get("16")
        if height and height.get("path"):
            icons[name] = height["path"]

    if not icons:
        sys.exit("No 16px icons found in data.json: check the package layout.")

    for alias, target in ALIASES.items():
        if target not in icons:
            sys.exit(f"Alias target '{target}' missing from the octicon set.")
        icons[alias] = icons[target]

    icons["marketplace"] = MARKETPLACE

    out = pathlib.Path(__file__).resolve().parent.parent / "_extensions" / "gitlink" / "octicons.json"
    out.write_text(json.dumps(icons, sort_keys=True, separators=(",", ":")) + "\n")
    print(f"{out}: {len(icons)} icons, {out.stat().st_size} bytes")


if __name__ == "__main__":
    main()
