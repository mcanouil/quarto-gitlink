--[[
MIT License

Copyright (c) 2025 Mickaël Canouil

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
]]

--- @type string The platform type (github, gitlab, codeberg, gitea, bitbucket)
local platform = "github"

--- @type string|nil The repository name (e.g., "owner/repo")
local repository_name = nil

--- @type string The base URL for the Git hosting platform
local base_url = "https://github.com"

--- @type table<string, boolean> Set of reference IDs from the document
local references_ids_set = {}

--- @type table Platform-specific configuration
local platform_configs = {
  github = {
    default_url = "https://github.com",
    patterns = {
      issue = { "#(%d+)", "([^/]+/[^/#]+)#(%d+)", "GH%-(%d+)" },
      merge_request = { "#(%d+)", "([^/]+/[^/#]+)#(%d+)" }, -- Same as issue for GitHub
      commit = { "^(%x+)$", "([^/]+/[^/@]+)@(%x+)", "(%w+)@(%x+)" }, -- Use %x for hexadecimal
      user = "@([%w%-%.]+)"
    },
    url_formats = {
      issue = "/{repo}/issues/{number}",
      pull = "/{repo}/pull/{number}",
      commit = "/{repo}/commit/{sha}",
      user = "/{username}"
    }
  },
  gitlab = {
    default_url = "https://gitlab.com",
    patterns = {
      issue = { "#(%d+)", "([^/]+/[^/#]+)#(%d+)" },
      merge_request = { "!(%d+)", "([^/]+/[^/#]+)!(%d+)" },
      commit = { "^(%x+)$", "([^/]+/[^/@]+)@(%x+)", "(%w+)@(%x+)" }, -- Use %x for hexadecimal
      user = "@([%w%-%.]+)"
    },
    url_formats = {
      issue = "/{repo}/-/issues/{number}",
      merge_request = "/{repo}/-/merge_requests/{number}",
      commit = "/{repo}/-/commit/{sha}",
      user = "/{username}"
    }
  },
  codeberg = {
    default_url = "https://codeberg.org",
    patterns = {
      issue = { "#(%d+)", "([^/]+/[^/#]+)#(%d+)" },
      merge_request = { "#(%d+)", "([^/]+/[^/#]+)#(%d+)" }, -- Same as issue for Codeberg/Forgejo
      commit = { "^(%x+)$", "([^/]+/[^/@]+)@(%x+)", "(%w+)@(%x+)" }, -- Use %x for hexadecimal
      user = "@([%w%-%.]+)"
    },
    url_formats = {
      issue = "/{repo}/issues/{number}",
      pull = "/{repo}/pulls/{number}",
      commit = "/{repo}/commit/{sha}",
      user = "/{username}"
    }
  },
  gitea = {
    default_url = "https://gitea.com",
    patterns = {
      issue = { "#(%d+)", "([^/]+/[^/#]+)#(%d+)" },
      merge_request = { "!(%d+)", "([^/]+/[^/#]+)!(%d+)" },
      commit = { "^(%x+)$", "([^/]+/[^/@]+)@(%x+)", "(%w+)@(%x+)" }, -- Use %x for hexadecimal
      user = "@([%w%-%.]+)"
    },
    url_formats = {
      issue = "/{repo}/issues/{number}",
      pull = "/{repo}/pulls/{number}",
      commit = "/{repo}/commit/{sha}",
      user = "/{username}"
    }
  },
  bitbucket = {
    default_url = "https://bitbucket.org",
    patterns = {
      issue = { "#(%d+)", "([^/]+/[^/#]+)#(%d+)" },
      merge_request = { "#(%d+)", "([^/]+/[^/#]+)#(%d+)" }, -- Same as issue for Bitbucket
      commit = { "^(%x+)$", "([^/]+/[^/@]+)@(%x+)", "(%w+)@(%x+)" }, -- Use %x for hexadecimal
      user = "@([%w%-%.]+)"
    },
    url_formats = {
      issue = "/{repo}/issues/{number}",
      pull = "/{repo}/pull-requests/{number}",
      commit = "/{repo}/commits/{sha}",
      user = "/{username}"
    }
  }
}

--- Check if a string is empty or nil
--- @param s string|nil The string to check
--- @return boolean true if the string is nil or empty
local function is_empty(s)
  return s == nil or s == ''
end

--- Escape special pattern characters in a string
--- @param s string The string to escape
--- @return string The escaped string
local function escape_pattern(s)
  local escaped = s:gsub("([%^%$%(%)%%%.%[%]%*%+%-%?])", "%%%1")
  return escaped
end

--- Create a Git hosting URI link element
--- @param text string|nil The link text
--- @param uri string|nil The URI to link to
--- @return pandoc.Link|nil A Pandoc Link element or nil if text or uri is empty
local function create_link(text, uri)
  if not is_empty(uri) and not is_empty(text) then
    return pandoc.Link({pandoc.Str(text --[[@as string]])}, uri --[[@as string]])
  end
  return nil
end

--- Extract metadata value from document meta using nested structure
--- @param meta table The document metadata table
--- @param key string The metadata key to retrieve
--- @return string|nil The metadata value as a string, or nil if not found
local function get_metadata_value(meta, key)
  -- Check for the nested structure: extensions.githost.key
  if meta['extensions'] and meta['extensions']['githost'] and meta['extensions']['githost'][key] then
    return pandoc.utils.stringify(meta['extensions']['githost'][key])
  end

  return nil
end

--- Get platform configuration
--- @param platform_name string The platform name
--- @return table|nil The platform configuration or nil if not found
local function get_platform_config(platform_name)
  return platform_configs[platform_name:lower()]
end

--- Get repository name from metadata or git remote
--- This function extracts the repository name either from document metadata
--- or by querying the git remote origin URL
--- @param meta table The document metadata table
--- @return table The metadata table (unchanged)
function get_repository(meta)
  local meta_platform = get_metadata_value(meta, 'platform')
  local meta_base_url = get_metadata_value(meta, 'base-url')
  local meta_repository = get_metadata_value(meta, 'repository-name')

  -- Set platform
  if not is_empty(meta_platform) then
    platform = (meta_platform --[[@as string]]):lower()
  else
    platform = "github" -- default platform
  end

  -- Get platform configuration
  local config = get_platform_config(platform)
  if not config then
    quarto.log.error("Unsupported platform: " .. platform)
    return meta
  end

  -- Set base URL
  if not is_empty(meta_base_url) then
    base_url = meta_base_url --[[@as string]]
  else
    base_url = config.default_url
  end

  -- Get repository name
  if is_empty(meta_repository) then
    local is_windows = package.config:sub(1, 1) == "\\"
    local remote_repository_command
    
    if is_windows then
      remote_repository_command = "(git remote get-url origin) -replace '.*[:/](.+?)(\\.git)?$', '$1'"
    else
      remote_repository_command = "git remote get-url origin 2>/dev/null | sed -E 's|.*[:/]([^/]+/[^/.]+)(\\.git)?$|\\1|'"
    end

    local handle = io.popen(remote_repository_command)
    if handle then
      local git_repo = handle:read("*a"):gsub("%s+$", "")
      handle:close()
      if not is_empty(git_repo) then
        meta_repository = git_repo
      end
    end
  end

  repository_name = meta_repository
  return meta
end

--- Extract and store reference IDs from the document
--- This function collects all reference IDs from the document to distinguish
--- between actual citations and Git hosting mentions
--- @param doc pandoc.Pandoc The Pandoc document
--- @return pandoc.Pandoc The document (unchanged)
function get_references(doc)
  local references = pandoc.utils.references(doc)
  for _, reference in ipairs(references) do
    if reference.id then
      references_ids_set[reference.id] = true
    end
  end
  return doc
end

--- Process Git hosting mentions in citations
--- Distinguishes between actual bibliography citations and Git hosting @mentions
--- @param cite pandoc.Cite The citation element
--- @return pandoc.Cite|pandoc.Link The original citation or a Git hosting mention link
function process_mentions(cite)
  if references_ids_set[cite.citations[1].id] then
    return cite
  else
    local mention_text = pandoc.utils.stringify(cite.content)
    local config = get_platform_config(platform)
    if config and config.patterns.user then
      local username = mention_text:match(config.patterns.user)
      if username then
        local url_format = config.url_formats.user
        local uri = base_url .. url_format:gsub("{username}", username)
        local link = create_link(mention_text, uri)
        return link or cite
      end
    end
    return cite
  end
end

--- Process issues and merge requests
--- @param elem pandoc.Str The string element to process
--- @return pandoc.Link|nil A link or nil if no valid pattern found
function process_issues_and_mrs(elem)
  local config = get_platform_config(platform)
  if not config then
    return nil
  end

  local text = elem.text
  local repo = nil
  local number = nil
  local ref_type = nil
  local short_link = nil

  -- Try issue patterns
  for _, pattern in ipairs(config.patterns.issue) do
    if pattern == "#(%d+)" and text:match("^#(%d+)$") then
      number = text:match("^#(%d+)$")
      repo = repository_name
      ref_type = "issue"
      short_link = "#" .. number
      break
    elseif pattern == "([^/]+/[^/#]+)#(%d+)" and text:match("^([^/]+/[^/#]+)#(%d+)$") then
      repo, number = text:match("^([^/]+/[^/#]+)#(%d+)$")
      ref_type = "issue"
      short_link = repo .. "#" .. number
      break
    elseif pattern == "GH%-(%d+)" and text:match("^GH%-(%d+)$") then
      number = text:match("^GH%-(%d+)$")
      repo = repository_name
      ref_type = "issue"
      short_link = "#" .. number
      break
    end
  end

  -- Try merge request patterns if no issue found
  if not number and config.patterns.merge_request then
    for _, pattern in ipairs(config.patterns.merge_request) do
      if pattern == "!(%d+)" and text:match("^!(%d+)$") then
        number = text:match("^!(%d+)$")
        repo = repository_name
        ref_type = "merge_request"
        short_link = "!" .. number
        break
      elseif pattern == "([^/]+/[^/#]+)!(%d+)" and text:match("^([^/]+/[^/#]+)!(%d+)$") then
        repo, number = text:match("^([^/]+/[^/#]+)!(%d+)$")
        ref_type = "merge_request"
        short_link = repo .. "!" .. number
        break
      end
    end
  end

  -- Try URL pattern matching
  if not number then
    local escaped_base_url = escape_pattern(base_url)
    local url_pattern_issue = "^" .. escaped_base_url .. "/([^/]+/[^/]+)/[^/]+issues?[^/]*/(%d+)$"
    local url_pattern_mr = "^" .. escaped_base_url .. "/([^/]+/[^/]+)/[^/]*merge[_%-]?requests?[^/]*/(%d+)$"
    local url_pattern_pull = "^" .. escaped_base_url .. "/([^/]+/[^/]+)/[^/]*pulls?[^/]*/(%d+)$"

    if text:match(url_pattern_issue) then
      repo, number = text:match(url_pattern_issue)
      ref_type = "issue"
      if repo == repository_name then
        short_link = "#" .. number
      else
        short_link = repo .. "#" .. number
      end
    elseif text:match(url_pattern_mr) then
      repo, number = text:match(url_pattern_mr)
      ref_type = "merge_request"
      if repo == repository_name then
        short_link = "!" .. number
      else
        short_link = repo .. "!" .. number
      end
    elseif text:match(url_pattern_pull) then
      repo, number = text:match(url_pattern_pull)
      ref_type = "pull"
      if repo == repository_name then
        short_link = "#" .. number
      else
        short_link = repo .. "#" .. number
      end
    end
  end

  if number and repo and ref_type then
    local url_format
    if ref_type == "issue" then
      url_format = config.url_formats.issue
    elseif ref_type == "merge_request" then
      url_format = config.url_formats.merge_request
    elseif ref_type == "pull" then
      url_format = config.url_formats.pull
    end

    if url_format then
      local uri = base_url .. url_format:gsub("{repo}", repo):gsub("{number}", number)
      return create_link(short_link, uri)
    end
  end

  return nil
end

--- Process commit references
--- @param elem pandoc.Str The string element to process
--- @return pandoc.Link|nil A commit link or nil if no valid pattern found
function process_commits(elem)
  local config = get_platform_config(platform)
  if not config then
    return nil
  end

  local text = elem.text
  local repo = nil
  local commit_sha = nil
  local short_link = nil

  -- Try commit patterns
  for _, pattern in ipairs(config.patterns.commit) do
    if pattern == "^(%x+)$" and text:match("^(%x+)$") and text:len() >= 7 and text:len() <= 40 then
      -- Only match hexadecimal characters (valid for git SHA)
      commit_sha = text:match("^(%x+)$")
      repo = repository_name
      short_link = commit_sha:sub(1, 7)
      break
    elseif pattern == "([^/]+/[^/@]+)@(%x+)" and text:match("^([^/]+/[^/@]+)@(%x+)$") then
      -- Only match hexadecimal characters for commit SHA
      repo, commit_sha = text:match("^([^/]+/[^/@]+)@(%x+)$")
      short_link = repo .. "@" .. commit_sha:sub(1, 7)
      break
    elseif pattern == "(%w+)@(%x+)" and text:match("^(%w+)@(%x+)$") then
      local user, sha = text:match("^(%w+)@(%x+)$")
      if sha:len() >= 7 and sha:len() <= 40 and repository_name then
        -- Extract repo name from repository_name for user-based commit reference
        local repo_part = repository_name:match("/(.+)")
        if repo_part then
          repo = user .. "/" .. repo_part
          commit_sha = sha
          short_link = user .. "@" .. sha:sub(1, 7)
          break
        end
      end
    end
  end

  -- Try URL pattern matching
  if not commit_sha then
    local escaped_base_url = escape_pattern(base_url)
    local url_pattern = "^" .. escaped_base_url .. "/([^/]+/[^/]+)/[^/]*commits?[^/]*/(%x+)$"
    if text:match(url_pattern) then
      repo, commit_sha = text:match(url_pattern)
      if commit_sha:len() >= 7 then -- Ensure it's a valid length SHA
        if repo == repository_name then
          short_link = commit_sha:sub(1, 7)
        else
          short_link = repo .. "@" .. commit_sha:sub(1, 7)
        end
      end
    end
  end

  if commit_sha and repo and commit_sha:len() >= 7 then
    local url_format = config.url_formats.commit
    local uri = base_url .. url_format:gsub("{repo}", repo):gsub("{sha}", commit_sha)
    return create_link(short_link, uri)
  end

  return nil
end

--- Main Git hosting processing function
--- Attempts to convert string elements into Git hosting links by trying different patterns
--- @param elem pandoc.Str The string element to process
--- @return pandoc.Str|pandoc.Link The original element or a Git hosting link
function process_githost(elem)
  if not platform or not base_url or is_empty(platform) then
    return elem
  end

  local link = nil

  -- Try issues and merge requests first
  if link == nil then
    link = process_issues_and_mrs(elem)
  end

  -- Try commits
  if link == nil then
    link = process_commits(elem)
  end

  if link == nil then
    return elem
  else
    return link
  end
end

--- Pandoc filter configuration
--- Defines the order of filter execution:
--- 1. Extract references from the document
--- 2. Get repository information from metadata
--- 3. Process string elements for Git hosting patterns
--- 4. Process citations for Git hosting mentions
return {
  { Pandoc = get_references },
  { Meta = get_repository },
  { Str = process_githost },
  { Cite = process_mentions }
}
