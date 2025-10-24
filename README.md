# Gitlink Extension For Quarto

A Quarto extension that automatically converts Git hosting platform references (issues, pull requests, commits, users) into clickable links. Supports **GitHub**, **GitLab**, **Codeberg**, **Gitea**, and **Bitbucket**.

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
    platform: github              # Platform: github, gitlab, codeberg, gitea, bitbucket
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

```yaml
extensions:
  gitlink:
    platform: gitea
    base-url: https://gitea.com
    repository-name: user/repo
```

**References:**

- Issues: `#123`, `user/repo#123`
- Pull Requests: `!123`, `user/repo!123`
- Commits: `e59ff077`, `user/repo@e59ff077`
- Users: `@username`

#### Bitbucket

```yaml
extensions:
  gitlink:
    platform: bitbucket
    base-url: https://bitbucket.org
    repository-name: workspace/repo
```

**References:**

- Issues/PRs: `#123`, `workspace/repo#123` (same format for both)
- Commits: `9cc27f2`, `workspace/repo@9cc27f2`
- Users: `@accountname`

### URL Processing

The extension automatically processes full URLs and converts them to short references:

**Input:** `https://github.com/owner/repo/issues/123`

**Output:** `owner/repo#123` (or `#123` if it's the current repository)

### Repository Detection

If `repository-name` is not specified, the extension attempts to detect it from the Git remote:

```bash
git remote get-url origin
```

This works for most Git hosting platforms and extracts the `owner/repo` format from URLs like:

- `https://github.com/owner/repo.git`
- `git@gitlab.com:group/project.git`
- `ssh://git@codeberg.org/user/repo.git`

### Platform-Specific Features

#### GitHub Features

- Supports `GH-123` format for issues
- Pull requests use same format as issues (`#123`)
- Automatic 7-character SHA shortening for commits

#### GitLab Features

- Merge requests use `!123` format (distinct from issues)
- Issues use `#123` format
- URLs include `/-/` in the path structure
- Full SHA support with automatic shortening

#### Codeberg Features (Forgejo)

- Issues and pull requests both use `#123` format
- Follows Forgejo/Gitea conventions
- Automatic reference linking in comments

#### Gitea Features

- Issues use `#123` format
- Pull requests use `!123` format (GitLab-style)
- Supports both internal and external issue trackers
- Actionable references (closes, fixes, etc.)

#### Bitbucket Features

- Issues and pull requests both use `#123` format
- Pull request URLs use `/pull-requests/` path
- Workspace-based repository structure

## Examples

### Basic Usage

```markdown
See issue #123 for details.
Commit a5c3785 fixes the bug.
Thanks @contributor for the review!
```

### Cross-Repository References

```markdown
Related to mcanouil/quarto-github#45
Implemented in microsoft/vscode@9ba12248
```

### Full URL Processing

```markdown
Check this issue: https://github.com/owner/repo/issues/123
The fix is in: https://gitlab.com/group/project/-/commit/abc1234
```

## Example Document

Here is the source code for a comprehensive example: [example.qmd](example.qmd).

Output of `example.qmd`:

- [HTML](https://m.canouil.dev/quarto-gitlink/)
