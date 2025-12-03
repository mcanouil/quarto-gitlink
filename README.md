# Gitlink Extension For Quarto

A Quarto extension that automatically converts Git hosting platform references (issues, pull requests, commits, users) into clickable links. Supports **GitHub**, **GitLab**, **Codeberg**, **Gitea**, and **Bitbucket**.

## Features

- **Automatic URL shortening**: Converts long URLs into short, readable references.
- **Platform badges**: Displays subtle, always-visible platform badges in HTML output for improved accessibility.
- **Platform tooltips**: Shows the platform name on hover in HTML output (accessible via `title` attribute).
- **Platform labels**: Adds platform name in parentheses for non-HTML formats (PDF, DOCX, etc.).
- **Multi-platform support**: Works with GitHub, GitLab, Codeberg, Gitea, and Bitbucket.
- **Cross-repository references**: Link to issues, PRs, and commits in other repositories.
- **User mentions**: Convert user profile URLs to `@username` format.

## Installation

```bash
quarto add mcanouil/quarto-gitlink
```

This will install the extension under the `_extensions` subdirectory.

If you're using version control, you will want to check in this directory.

## Usage

### Basic Configuration

Add the extension to your document's YAML front matter:

```yaml
---
title: "My Document"
filters:
  - path: gitlink
    at: post-quarto
extensions:
  gitlink:
    platform: github               # Platform: github, gitlab, codeberg, gitea, bitbucket
    base-url: https://github.com   # Base URL (optional, auto-detected from platform)
    repository-name: owner/repo    # Repository name for relative references
---
```

- Old (<1.8.21):

  ```yml
  filters:
    - quarto
    - gitlink
  ```

- New (>=1.8.21):

  ```yml
  filters:
    - path: gitlink
      at: post-quarto
  ```

## Supported Platforms

Each platform has different reference formats. Choose your platform below:

### GitHub

Official documentation: [Autolinked references](https://docs.github.com/en/get-started/writing-on-github/working-with-advanced-formatting/autolinked-references-and-urls)

```yaml
extensions:
  gitlink:
    platform: github
    base-url: https://github.com
    repository-name: owner/repo
```

**References:**

- Issues/PRs: `#123`, `owner/repo#123`, `GH-123`
- Commits: `a5c3785`, `owner/repo@a5c3785`
- Users: `@username`

### GitLab

Official documentation: [GitLab Flavored Markdown](https://docs.gitlab.com/ee/user/markdown.html#gitlab-specific-references)

```yaml
extensions:
  gitlink:
    platform: gitlab
    base-url: https://gitlab.com
    repository-name: group/project
```

**References:**

- Issues: `#123`, `group/project#123`
- Merge Requests: `!456`, `group/project!456`
- Commits: `9ba12248`, `group/project@9ba12248`
- Users: `@username`

### Codeberg

Official documentation: [Codeberg Documentation](https://docs.codeberg.org/) (uses Forgejo)

```yaml
extensions:
  gitlink:
    platform: codeberg
    base-url: https://codeberg.org
    repository-name: user/repo
```

**References:**

- Issues/PRs: `#123`, `user/repo#123` (same format for both)
- Commits: `e59ff077`, `user/repo@e59ff077`
- Users: `@username`

### Gitea

Official documentation: [Gitea Documentation](https://docs.gitea.com/usage/issues-prs/automatically-linked-references)

```yaml
extensions:
  gitlink:
    platform: gitea
    base-url: https://gitea.com
    repository-name: user/repo
```

**References:**

- Issues/PRs: `#123`, `user/repo#123` (same format for both)
- Commits: `e59ff077`, `user/repo@e59ff077`
- Users: `@username`

### Bitbucket

Official documentation: [Bitbucket markup syntax](https://support.atlassian.com/bitbucket-cloud/docs/markup-comments/)

```yaml
extensions:
  gitlink:
    platform: bitbucket
    base-url: https://bitbucket.org
    repository-name: workspace/repo
```

**References:**

Bitbucket requires keyword prefixes:

- Issues: `issue #123`, `issue workspace/repo#123`
- Pull Requests: `pull request #456`, `pull request workspace/repo#456`
- Commits: `9cc27f2`, `workspace/repo@9cc27f2`
- Users: `@accountname`

> [!NOTE]
> The `issue` and `pull request` keywords are required to distinguish reference types.

## Features and Configuration

### URL Processing

The extension automatically processes full URLs and converts them to short references:

**Input:** `https://github.com/owner/repo/issues/123`
**Output:** `owner/repo#123` (or `#123` if current repository)

> [!TIP]
> Wrap URLs in angle brackets (`<URL>`) for best results instead of bare URLs.

### Repository Detection

If `repository-name` is not specified, the extension auto-detects from git remote:

```bash
git remote get-url origin
```

Supports: `https://github.com/owner/repo.git`, `git@gitlab.com:group/project.git`, `ssh://git@codeberg.org/user/repo.git`

### Platform Badges

In HTML output, Gitlink adds subtle platform badges to links. You can control them with:

```yaml
extensions:
  gitlink:
    show-platform-badge: true      # Show/hide badges (default: true)
    badge-position: "after"        # "after" or "before" link (default: "after")
```

Badges are always visible, accessible, styled with Bootstrap, and include tooltips. In non-HTML formats, platform names appear in parentheses (e.g., `#123 (GitHub)`).

## Custom Platforms

You can add support for additional Git hosting platforms by creating a custom YAML configuration file.

### Creating a Custom Platform

Create a YAML file (e.g., `my-platforms.yml`):

```yaml
platforms:
  gitplatform:
    default-url: https://git.example.com
    patterns:
      issue:
        - '#(%d+)'
        - '([^/]+/[^/#]+)#(%d+)'
      merge-request:
        - '#(%d+)'
        - '([^/]+/[^/#]+)#(%d+)'
      commit:
        - '^(%x+)$'
        - '([^/]+/[^/@]+)@(%x+)'
        - '(%w+)@(%x+)'
      user: '@([%w%-%.]+)'
    url-formats:
      issue: '/{repo}/issues/{number}'
      merge-request: '/{repo}/pull/{number}'
      pull: '/{repo}/pulls/{number}'
      commit: '/{repo}/commit/{sha}'
      user: '/{username}'
```

Reference it in your document:

```yaml
extensions:
  gitlink:
    platform: gitplatform
    custom-platforms-file: my-platforms.yml
    repository-name: owner/repo
```

### Platform Configuration Schema Reference

Every platform configuration must follow this schema for validation and proper functionality.

#### Platform Configuration Structure

```yaml
platforms:
  platform_name:
    default-url: string                  # Required: Base URL for the platform
    patterns:
      issue: [string, ...]               # Required: Lua regex patterns for issues
      merge-request: [string, ...]       # Required: Lua regex patterns for merge requests/PRs
      commit: [string, ...]              # Required: Lua regex patterns for commits
      user: string                       # Required: Lua regex pattern for user mentions
    url-formats:
      issue: string                      # Required: URL template for issues
      pull: string                       # Required: URL template for pull requests
      commit: string                     # Required: URL template for commits
      user: string                       # Required: URL template for user profiles
      merge-request: string              # Required: URL template for merge requests
```

#### Field Descriptions

**default-url** (required, string):

- The base URL of the Git hosting platform.
- Must start with `http://` or `https://`.
- Example: `https://git.example.com`

**patterns** (required, object):

- Regular expressions for matching references.
- Uses Lua regex syntax.
- Must contain four pattern types.

**patterns.issue** (required, array of strings):

- Lua regex patterns for matching issue references.
- Should have 1-2 patterns (single issue, cross-repository issue).
- Example: `['#(%d+)', '([^/]+/[^/#]+)#(%d+)']`

**patterns.merge-request** (required, array of strings):

- Lua regex patterns for matching merge request/pull request references.
- Should have 1-2 patterns (similar to issue patterns).
- Example: `['!(%d+)', '([^/]+/[^/#]+)!(%d+)']`

**patterns.commit** (required, array of strings):

- Lua regex patterns for matching commit references.
- Should have 2-3 patterns (SHA, cross-repository, user@SHA).
- Example: `['^(%x+)$', '([^/]+/[^/@]+)@(%x+)', '(%w+)@(%x+)']`

**patterns.user** (required, string):

- Single Lua regex pattern for matching user mentions.
- Typically starts with `@`.
- Example: `'@([%w%-%.]+)'`

**url-formats** (required, object):

- URL templates for generating links.
- Must contain five format types.

**url-formats.issue** (required, string):

- Template for issue URLs.
- Placeholders: `{repo}` (repository), `{number}` (issue number).
- Example: `'/{repo}/issues/{number}'`

**url-formats.pull** (required, string):

- Template for pull request URLs.
- Placeholders: `{repo}`, `{number}`.
- Example: `'/{repo}/pull/{number}'`

**url-formats.merge-request** (required, string):

- Template for merge request URLs.
- Placeholders: `{repo}`, `{number}`.
- Example: `'/{repo}/-/merge_requests/{number}'`

**url-formats.commit** (required, string):

- Template for commit URLs.
- Placeholders: `{repo}`, `{sha}` (commit hash).
- Example: `'/{repo}/commit/{sha}'`

**url-formats.user** (required, string):

- Template for user profile URLs.
- Placeholder: `{username}`.
- Example: `'/{username}'`

#### Lua Regex Pattern Guide

Common patterns used in Gitlink configurations:

| Pattern                | Matches                   | Example           |
| ---------------------- | ------------------------- | ----------------- |
| `#(%d+)`               | Issue with number         | `#123`            |
| `!(%d+)`               | Merge request with number | `!456`            |
| `(%x+)`                | Hexadecimal string (SHA)  | `a5c3785d9`       |
| `@([%w%-%.]+)`         | User mention              | `@username`       |
| `([^/]+/[^/#]+)#(%d+)` | Cross-repo issue          | `owner/repo#123`  |
| `^(%x+)$`              | Full commit SHA           | `abc123def`       |
| `(%w+)@(%x+)`          | User with commit          | `username@abc123` |

#### Validation Rules

Platform configurations are automatically validated for:

1. **Required fields**: `default-url`, `patterns`, `url-formats` must all exist.
2. **Pattern syntax**: All regex patterns are checked for valid Lua regex syntax.
3. **URL format syntax**: URL templates must start with `/` and contain at least one placeholder.
4. **Field completeness**: All required pattern and format types must be defined.
5. **Type correctness**: Patterns must be arrays, URL formats must be strings.

#### Validation Errors

If your platform configuration is invalid, you will see detailed error messages such as:

- `Missing required field: "patterns"` - The patterns object is missing.
- `Invalid Lua regex in issue[1]: ... bad escape ...` - Pattern has invalid regex syntax.
- `Missing required pattern type: "commit"` - A required pattern type is missing.
- `Missing required URL format: "pull"` - A required URL format is missing.
- `Invalid url-formats.issue: URL format must contain at least one placeholder` - Template missing placeholders.

#### Example: Complete Gitea Platform

```yaml
platforms:
  gitea:
    default-url: https://gitea.io
    patterns:
      issue:
        - '#(%d+)'
        - '([^/]+/[^/#]+)#(%d+)'
      merge-request:
        - '#(%d+)'
        - '([^/]+/[^/#]+)#(%d+)'
      commit:
        - '^(%x+)$'
        - '([^/]+/[^/@]+)@(%x+)'
        - '(%w+)@(%x+)'
      user: '@([%w%-%.]+)'
    url-formats:
      issue: '/{repo}/issues/{number}'
      pull: '/{repo}/pulls/{number}'
      merge-request: '/{repo}/pulls/{number}'
      commit: '/{repo}/commit/{sha}'
      user: '/{username}'
```

#### Testing Custom Platforms

After creating a custom platform YAML file, you can validate it by:

1. Using the Gitlink extension with `custom-platforms-file` option.
2. Checking the Quarto output for validation errors.
3. Creating a test document and running `quarto render`.

### Contributing New Platforms

To add a new platform to the built-in configuration:

1. Fork the repository.
2. Edit [`_extensions/gitlink/platforms.yml`](_extensions/gitlink/platforms.yml).
3. Test your configuration using a custom platforms file first.
4. Submit a pull request.

This approach makes it easy to add support for new platforms without modifying Lua code.

## Example Document

Here is the source code for a comprehensive example: [example.qmd](example.qmd).

Output of `example.qmd`:

- [HTML](https://m.canouil.dev/quarto-gitlink/)
