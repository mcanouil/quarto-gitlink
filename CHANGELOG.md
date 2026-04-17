# Changelog

## Unreleased

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
