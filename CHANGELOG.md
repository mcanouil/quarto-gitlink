# Changelog

## Unreleased

### Bug Fixes

- fix: Register the filter at `post-quarto` in the extension manifest, so listing `gitlink` under `filters` is enough and the entry point no longer has to be named in project or document YAML. The long form `path`/`at` overrides the entry point of every filter an extension contributes, so it is best avoided.
- fix: Raise `quarto-required` to `>=1.9.38`, the first version whose `_extension.yml` schema accepts a filter entry point.

## 1.9.2 (2026-08-01)

### Documentation

- docs: Add a documentation website under `docs/`, built on the `atelier` project type and published to <https://m.canouil.dev/quarto-gitlink/>, with in-text rewriting enabled so the pages show the filter working.
- docs: Trim `README.md` to a landing page pointing at the website.
- docs: Add the Pages workflow, which renders `docs/` on pull requests and deploys it from the release tag.
- docs: Add the Quarto Extensions Updates workflow, scanning `docs` for the website's own dependencies.

## 1.9.1 (2026-08-01)

### Bug Fixes

- fix: Keep a sidebar tools widget's menu inside the sidebar, so a docked sidebar carrying the widget no longer has a permanent horizontal scrollbar. Quarto's sidebar sets `overflow-y: auto` and leaves `overflow-x` at `visible`, which computes to `auto`, so a menu wider than the column scrolled it sideways instead of being clipped; the menu was anchored to the centred trigger and sized to its content, so it ran past the right edge, and because it is hidden with `visibility` rather than `display` it did so even while shut. The menu is now stretched between both edges of the tools row, which spans the column. The navbar and `sidebar.contents` placements are unaffected.

## 1.9.0 (2026-07-31)

### New Features

- feat: Support the repository widget in the sidebar, so book-like sites with `navbar: false` can use it; the `#gitlink-widget` placeholder goes in `sidebar.tools` or `sidebar.contents`, and both may be used on the same site.
- feat: Fit the widget to Quarto's sidebar navigation: a tools widget takes its own centred line below the colour-scheme and reader toggles and above search, with an overlay menu, while a contents widget spans the sidebar width and expands its menu inline so the sidebar scroll area never clips it.
- feat: Replace every `#gitlink-widget` placeholder on a page instead of only the first; each widget gets unique element ids, and they share a single stats request.

## 1.8.0 (2026-07-24)

### New Features

- feat: Add `gitlink.widget` navbar widget for HTML websites, replacing a navbar item with href `#gitlink-widget` by a button showing live star/fork counts (fetched from the platform API, cached for four hours) and a dropdown of repository links.
- feat: Add per-platform `widget` sections to `platforms.yml` (menu paths, labels, stats API endpoint and fields) for GitHub, GitLab, Codeberg, Gitea, and Bitbucket; Bitbucket renders without counters as its API exposes no star count.
- feat: Add `gitlink.widget.links` toggles, `gitlink.widget.extra-links` custom entries, `gitlink.widget.sponsor`, and `gitlink.widget.icon` options to customise the dropdown; `icon` takes Quarto's bundled Bootstrap icon names (as in navbar tools) or one of about sixty embedded octicons (16px bodies from primer/octicons), and shortcode output in an entry's `text` (e.g. iconify) is preserved when the filter runs at post-quarto.
- feat: Size Quarto's navbar search button and colour-scheme toggle to match the widget, with consistent spacing across the navbar-right control group; the optional `gitlink.widget.style-navbar-tools` option additionally applies the widget's bordered pill style to both.
- feat: Allow widget-only usage with `gitlink.enabled: false` and `gitlink.widget.enabled: true`.

## 1.7.0 (2026-07-21)

### Bug Fixes

- fix: Recognise groups of references separated by commas, both spaced (`(#2, #3)`, `(#1, #2, #3)`) and without spaces (`(#2,#3)`, `#2,#3`); a comma-separated group is linked only when every item is a valid reference.
- fix: Shorten autolinked platform URLs (e.g. `<https://github.com/owner/repo/issues/1>`) to a single clean reference link instead of a malformed nested link; non-platform autolinks keep their original link.

## 1.6.0 (2026-05-31)

### New Features

- feat: Add `gitlink.enabled` option so drafts and templates can opt out of link rewriting.
- feat: Add `gitlink.normalize-links` option to toggle URL shortening of autolinked platform URLs.
- feat: Add `gitlink.fetch-titles` option to use the page title of an autolinked platform URL as the link text (best-effort via `curl`).
- feat: Add `gitlink.mentions` list to force-treat specific citation IDs as Git hosting mentions even when a bibliography reference with the same id exists.

### Bug Fixes

- fix: Validate `badge-background-colour` and `badge-text-colour` against hex codes and CSS named colours; invalid values are now warned and ignored instead of producing broken inline styles or invalid Typst `rgb()` calls.
- fix: Reject cross-repository commit references (`owner/repo@<sha>`) whose SHA is shorter than 7 or longer than 40 hexadecimal characters; previously over-length SHAs produced an incorrect link.
- fix: Reset module-level state at the start of each document so batch renders no longer leak platform, repository, badge, or reference-set state across documents.
- fix: Respect boolean `false` for `show-platform-badge`, `enabled`, and `normalize-links` (the previous metadata accessor treated `false` as missing).

### Refactoring

- refactor: Cache platform-config lookups per render to avoid repeated module calls on every Str element.
- refactor: Add canonical `colour.lua` shared module for hex/named colour validation.

## 1.5.2 (2026-04-17)

### Bug Fixes

- fix: Recognise references inside bracket pairs surrounded by additional text or punctuation, e.g. `something(#1)`, `(#1).`, `.(#1).`, `(mcanouil/quarto-gitlink#1)something`.

## 1.5.1 (2026-04-15)

### Refactoring

- refactor: Synchronise shared modules (`logging.lua`, `git.lua`, `string.lua`) with canonical versions.

## 1.5.0 (2026-04-15)

### New Features

- feat: Support references surrounded by parentheses, brackets, quotes, and trailing punctuation.

## 1.4.0 (2026-04-09)

### New Features

- feat: Auto-detect repository from Quarto project `repo-url` for website and book projects.

## 1.3.0 (2026-03-23)

### Refactoring

- refactor: Replace monolithic `utils.lua` with focused modules (`string.lua`, `logging.lua`, `metadata.lua`, `pandoc-helpers.lua`, `html.lua`, `paths.lua`, `colour.lua`).

## 1.2.0 (2026-02-21)

### New Features

- feat: Add extension-provided code snippets (#22).
- feat: Add _schema.yml for configuration validation and IDE support (#18).

## 1.1.1 (2026-02-11)

### Bug Fixes

- fix: Update copyright year.

## 1.1.0 (2025-12-04)

### New Features

- feat: Add support for custom Git hosting platforms and schema validation (#15).
- feat: Shorten URLs (#14).

### Documentation

- docs: Drop old filter syntax.
- docs: Remove outdated comments and use panel tabset.
- docs: Tip about not using bare URLs.

## 1.0.0 (2025-11-30)

### Bug Fixes

- fix: Update and fix Bitbucket support and update documentation (#10).
- fix: Gitea pattern.
- fix: Missing import prefix.

### Refactoring

- refactor: Use module structure and enhance dependency management (#9).

## 0.1.0 (2025-08-23)

### New Features

- feat: Initial implementation of githost extension for Quarto (#1).

### Bug Fixes

- fix: Change output-file.

### Refactoring

- refactor: Rename extension directory.
- refactor: Rename extension to gitlink (#7).
