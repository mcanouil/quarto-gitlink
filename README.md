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

### Supported Platforms and Reference Formats

#### GitHub

Official documentation: [Autolinked references](https://docs.github.com/en/get-started/writing-on-github/working-with-advanced-formatting/autolinked-references-and-urls)

```yaml
extensions:
  gitlink:
    platform: github
    base-url: https://github.com
    repository-name: owner/repo
```

**References:**

- Issues/PRs: `#123`, `owner/repo#123`
- Commits: `a5c3785`, `owner/repo@a5c3785`
- Users: `@username`

#### GitLab

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

#### Codeberg

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

#### Gitea

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

#### Bitbucket

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

### URL Processing

The extension automatically processes full URLs and converts them to the appropriate short references:

**Input:** `https://github.com/owner/repo/issues/123`

**Output:** `owner/repo#123` (or `#123` if it's the current repository)

> [!TIP]
> For best results, wrap URLs in angle brackets (`<URL>`) rather than using bare URLs.
> For example, use `<https://github.com/owner/repo/issues/123>` instead of `https://github.com/owner/repo/issues/123`.

### Repository Detection

If `repository-name` is not specified, the extension attempts to detect it from the Git remote:

```bash
git remote get-url origin
```

This works for most Git hosting platforms and extracts the `owner/repo` format from URLs like:

- `https://github.com/owner/repo.git`
- `git@gitlab.com:group/project.git`
- `ssh://git@codeberg.org/user/repo.git`

### Platform Badges

In HTML output, Gitlink adds subtle platform badges to links, making it easy to identify which platform a link references at a glance.

Platform badges are:

- Always visible (not just on hover).
- Accessible to screen readers with proper ARIA labels.
- Styled using Bootstrap for automatic theme compatibility.
- Accompanied by tooltips with full platform names.

You can control badge appearance using metadata options:

```yaml
extensions:
  gitlink:
    show-platform-badge: true      # Show/hide badges (default: true)
    badge-position: "after"        # "after" or "before" link (default: "after")
```

**Configuration Options**:

- `show-platform-badge` (boolean): Toggle badge visibility, default `true`.
- `badge-position` (string): Badge placement relative to link, default `"after"`.

In non-HTML formats, platform names appear in parentheses after the link text, such as `#123 (GitHub)`.

### Platform-Specific Features

#### GitHub Features

- Supports `GH-123` format for issues
- Pull requests use same format as issues (`#123`)
- Automatic 7-character SHA shortening for commits
- Reference: [GitHub Autolinked references](https://docs.github.com/en/get-started/writing-on-github/working-with-advanced-formatting/autolinked-references-and-urls)

#### GitLab Features

- Merge requests use `!123` format (distinct from issues)
- Issues use `#123` format
- URLs include `/-/` in the path structure
- Full SHA support with automatic shortening
- Reference: [GitLab Flavored Markdown](https://docs.gitlab.com/ee/user/markdown.html#gitlab-specific-references)

#### Codeberg Features (Forgejo)

- Issues and pull requests both use `#123` format
- Follows Forgejo/Gitea conventions
- Automatic reference linking in comments
- Reference: [Codeberg Documentation](https://docs.codeberg.org/)

#### Gitea Features

- Issues use `#123` format
- Pull requests use `#123` format (same as issues)
- Supports both internal and external issue trackers
- Actionable references (closes, fixes, etc.)
- Reference: [Gitea Documentation](https://docs.gitea.com/usage/issues-prs/automatically-linked-references)

#### Bitbucket Features

- Issues require `issue #123` format (with "issue" keyword)
- Pull requests require `pull request #456` format (with "pull request" keyword)
- Cross-repository references: `issue workspace/repo#123` or `pull request workspace/repo#456`
- Pull request URLs use `/pull-requests/` path
- Workspace-based repository structure
- Follows [official Bitbucket markup syntax](https://support.atlassian.com/bitbucket-cloud/docs/markup-comments/)

## Example Document

Here is the source code for a comprehensive example: [example.qmd](example.qmd).

Output of `example.qmd`:

- [HTML](https://m.canouil.dev/quarto-gitlink/)
