--[[
# MIT License
#
# Copyright (c) 2025 Mickaël Canouil
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.
]]

--- Extension name constant
local EXTENSION_NAME = "gitlink"

--- Load utils, git, bitbucket, and platforms modules
local utils = require(quarto.utils.resolve_path('_modules/utils.lua'):gsub('%.lua$', ''))
local git = require(quarto.utils.resolve_path('_modules/git.lua'):gsub('%.lua$', ''))
local bitbucket = require(quarto.utils.resolve_path('_modules/bitbucket.lua'):gsub('%.lua$', ''))
local platforms = require(quarto.utils.resolve_path('_modules/platforms.lua'):gsub('%.lua$', ''))

--- @type string The platform type (github, gitlab, codeberg, gitea, bitbucket)
local platform = "github"

--- @type string|nil The repository name (e.g., "owner/repo")
local repository_name = nil

--- @type string The base URL for the Git hosting platform
local base_url = "https://github.com"

--- @type table<string, boolean> Set of reference IDs from the document
local references_ids_set = {}

--- @type boolean Whether to show visible platform badges
local show_platform_badge = true

--- @type string Badge position: "after" or "before"
local badge_position = "after"

--- @type integer Full length of a git commit SHA
local COMMIT_SHA_FULL_LENGTH = 40

--- @type integer Short length for displaying commit SHA
local COMMIT_SHA_SHORT_LENGTH = 7

--- @type integer Minimum length for a valid git commit SHA
local COMMIT_SHA_MIN_LENGTH = 7

--- Get platform configuration
--- @param platform_name string The platform name
--- @return table|nil The platform configuration or nil if not found
local function get_platform_config(platform_name)
  return platforms.get_platform_config(platform_name:lower())
end

--- Create a link with platform label
--- @param text string|nil The link text
--- @param uri string|nil The URI
--- @param platform_name string|nil The platform name
--- @return pandoc.Link|pandoc.Span|nil A Pandoc Link element with platform label or Span containing link and badge
local function create_platform_link(text, uri, platform_name)
  if utils.is_empty(uri) or utils.is_empty(text) or utils.is_empty(platform_name) then
    return nil
  end

  local platform_names = {
    github = "GitHub",
    gitlab = "GitLab",
    codeberg = "Codeberg",
    gitea = "Gitea",
    bitbucket = "Bitbucket"
  }
  local platform_label = platform_names[(platform_name --[[@as string]]):lower()] or
      (platform_name --[[@as string]]):sub(1, 1):upper() .. (platform_name --[[@as string]]):sub(2)

  local link_content = { pandoc.Str(text --[[@as string]]) }
  local link_attr = pandoc.Attr('', {}, {})

  if quarto.doc.is_format("html:js") or quarto.doc.is_format("html") then
    link_attr = pandoc.Attr('', {}, { title = platform_label })
    local link = pandoc.Link(link_content, uri --[[@as string]], '', link_attr)

    if show_platform_badge then
      local css_path = quarto.utils.resolve_path("gitlink.css")
      utils.ensure_html_dependency({
        name = 'quarto-gitlink',
        version = '1.0.0',
        stylesheets = { css_path }
      })

      local badge_attr = pandoc.Attr(
        '',
        { 'gitlink-badge', 'badge', 'text-bg-secondary' },
        { title = platform_label, ['aria-label'] = platform_label .. ' platform' }
      )
      local badge = pandoc.Span({ pandoc.Str(platform_label) }, badge_attr)

      local inlines = {}
      if badge_position == "before" then
        inlines = { badge, pandoc.Space(), link }
      else
        inlines = { link, badge }
      end

      return pandoc.Span(inlines)
    else
      return link
    end
  else
    table.insert(link_content, pandoc.Space())
    table.insert(link_content, pandoc.Str("(" .. platform_label .. ")"))
    return pandoc.Link(link_content, uri --[[@as string]], '', link_attr)
  end
end

--- Get repository name from metadata or git remote
--- This function extracts the repository name either from document metadata
--- or by querying the git remote origin URL
--- @param meta table The document metadata table
--- @return table The metadata table (unchanged)
local function get_repository(meta)
  local meta_platform = utils.get_metadata_value(meta, 'gitlink', 'platform')
  local meta_base_url = utils.get_metadata_value(meta, 'gitlink', 'base-url')
  local meta_repository = utils.get_metadata_value(meta, 'gitlink', 'repository-name')
  local meta_custom_platforms = utils.get_metadata_value(meta, 'gitlink', 'custom-platforms-file')

  if not utils.is_empty(meta_custom_platforms) then
    local custom_file_path = meta_custom_platforms --[[@as string]]
    local ok, err = platforms.initialise(custom_file_path)
    if not ok then
      utils.log_error(
        EXTENSION_NAME,
        "Failed to load custom platforms from '" .. meta_custom_platforms .. "':\n" .. (err or 'unknown error')
      )
      return meta
    end
  else
    local ok, err = platforms.initialise()
    if not ok then
      utils.log_error(EXTENSION_NAME, "Failed to load built-in platforms:\n" .. (err or 'unknown error'))
      return meta
    end
  end

  if not utils.is_empty(meta_platform) then
    platform = (meta_platform --[[@as string]]):lower()
  else
    platform = 'github'
  end
  local config = get_platform_config(platform)
  if not config then
    local available_platforms = table.concat(platforms.get_all_platform_names(), ', ')
    utils.log_error(
      EXTENSION_NAME,
      "Unsupported platform: '" .. platform ..
      "'. Supported platforms are: " .. available_platforms .. '.'
    )
    return meta
  end

  if not utils.is_empty(meta_base_url) then
    base_url = meta_base_url --[[@as string]]
  else
    base_url = config.default_url
  end

  if utils.is_empty(meta_repository) then
    meta_repository = git.get_repository()
  end

  repository_name = meta_repository

  -- Read badge configuration
  local show_badge_meta = utils.get_metadata_value(meta, 'gitlink', 'show-platform-badge')
  if show_badge_meta ~= nil then
    show_platform_badge = (show_badge_meta == "true" or show_badge_meta == true)
  end

  local badge_pos_meta = utils.get_metadata_value(meta, 'gitlink', 'badge-position')
  if badge_pos_meta ~= nil then
    badge_position = badge_pos_meta --[[@as string]]
  end

  return meta
end

--- Extract and store reference IDs from the document
--- This function collects all reference IDs from the document to distinguish
--- between actual citations and Git hosting mentions
--- @param doc pandoc.Pandoc The Pandoc document
--- @return pandoc.Pandoc The document (unchanged)
local function get_references(doc)
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
local function process_mentions(cite)
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
        local link = create_platform_link(mention_text, uri, platform)
        return link or cite
      end
    end
    return cite
  end
end


--- Process issues and merge requests
--- @param elem pandoc.Str The string element to process
--- @param current_platform string The current platform name
--- @param current_base_url string The current base URL
--- @return pandoc.Link|nil A link or nil if no valid pattern found
--- @return string|nil The platform name used for this match
--- @return string|nil The base URL used for this match
local function process_issues_and_mrs(elem, current_platform, current_base_url)
  local config = get_platform_config(current_platform)
  if not config then
    return nil, nil, nil
  end

  local text = elem.text
  local repo = nil
  local number = nil
  local ref_type = nil
  local short_link = nil
  local matched_platform = current_platform
  local matched_base_url = current_base_url

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

  if not number then
    -- Try to match URLs from any supported platform
    local all_platform_names = platforms.get_all_platform_names()
    for _, platform_name in ipairs(all_platform_names) do
      local platform_config = platforms.get_platform_config(platform_name)
      if platform_config then
        local platform_base_url = platform_config.default_url
        local escaped_platform_url = utils.escape_pattern(platform_base_url)
        local url_pattern_issue = '^' .. escaped_platform_url .. '/([^/]+/[^/]+)/%-?/?issues?/(%d+)'
        local url_pattern_mr = '^' .. escaped_platform_url .. '/([^/]+/[^/]+)/%-?/?merge[_%-]requests/(%d+)'
        local url_pattern_pull_requests = '^' .. escaped_platform_url .. '/([^/]+/[^/]+)/%-?/?pull%-requests/(%d+)'
        local url_pattern_pull = '^' .. escaped_platform_url .. '/([^/]+/[^/]+)/%-?/?pulls?/(%d+)'

        if text:match(url_pattern_issue) then
          repo, number = text:match(url_pattern_issue)
          ref_type = 'issue'
          if repo == repository_name then
            short_link = '#' .. number
          else
            short_link = repo .. '#' .. number
          end
          matched_platform = platform_name
          matched_base_url = platform_base_url
          config = platform_config
          break
        elseif text:match(url_pattern_mr) then
          repo, number = text:match(url_pattern_mr)
          ref_type = 'merge_request'
          if repo == repository_name then
            short_link = '!' .. number
          else
            short_link = repo .. '!' .. number
          end
          matched_platform = platform_name
          matched_base_url = platform_base_url
          config = platform_config
          break
        elseif text:match(url_pattern_pull_requests) then
          repo, number = text:match(url_pattern_pull_requests)
          ref_type = 'pull'
          if repo == repository_name then
            short_link = '#' .. number
          else
            short_link = repo .. '#' .. number
          end
          matched_platform = platform_name
          matched_base_url = platform_base_url
          config = platform_config
          break
        elseif text:match(url_pattern_pull) then
          repo, number = text:match(url_pattern_pull)
          ref_type = 'pull'
          if repo == repository_name then
            short_link = '#' .. number
          else
            short_link = repo .. '#' .. number
          end
          matched_platform = platform_name
          matched_base_url = platform_base_url
          config = platform_config
          break
        end
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
      local uri = matched_base_url .. url_format:gsub("{repo}", repo):gsub("{number}", number)
      return create_platform_link(short_link, uri, matched_platform), matched_platform, matched_base_url
    end
  end

  return nil, nil, nil
end

--- Process user/organisation references
--- @param elem pandoc.Str The string element to process
--- @param current_platform string The current platform name
--- @return pandoc.Link|nil A user link or nil if no valid pattern found
--- @return string|nil The platform name used for this match
--- @return string|nil The base URL used for this match
local function process_users(elem, current_platform)
  local config = get_platform_config(current_platform)
  if not config then
    return nil, nil, nil
  end

  local text = elem.text
  local username = nil

  local all_platform_names = platforms.get_all_platform_names()
  for _, platform_name in ipairs(all_platform_names) do
    local platform_config = platforms.get_platform_config(platform_name)
    if platform_config then
      local platform_base_url = platform_config.default_url
      local escaped_platform_url = utils.escape_pattern(platform_base_url)
      local url_pattern = '^' .. escaped_platform_url .. '/([%w%-%.]+)$'

      if text:match(url_pattern) then
        username = text:match(url_pattern)
        if username then
          local url_format = platform_config.url_formats.user
          local uri = platform_base_url .. url_format:gsub('{username}', username)
          return create_platform_link('@' .. username, uri, platform_name), platform_name, platform_base_url
        end
      end
    end
  end

  return nil, nil, nil
end

--- Process commit references
--- @param elem pandoc.Str The string element to process
--- @param current_platform string The current platform name
--- @param current_base_url string The current base URL
--- @return pandoc.Link|nil A commit link or nil if no valid pattern found
--- @return string|nil The platform name used for this match
--- @return string|nil The base URL used for this match
local function process_commits(elem, current_platform, current_base_url)
  local config = get_platform_config(current_platform)
  if not config then
    return nil, nil, nil
  end

  local text = elem.text
  local repo = nil
  local commit_sha = nil
  local short_link = nil
  local matched_platform = current_platform
  local matched_base_url = current_base_url

  for _, pattern in ipairs(config.patterns.commit) do
    if pattern == "^(%x+)$" and text:match("^(%x+)$") and text:len() >= COMMIT_SHA_MIN_LENGTH and text:len() <= COMMIT_SHA_FULL_LENGTH then
      commit_sha = text:match("^(%x+)$")
      repo = repository_name
      short_link = commit_sha:sub(1, COMMIT_SHA_SHORT_LENGTH)
      break
    elseif pattern == "([^/]+/[^/@]+)@(%x+)" and text:match("^([^/]+/[^/@]+)@(%x+)$") then
      repo, commit_sha = text:match("^([^/]+/[^/@]+)@(%x+)$")
      short_link = repo .. "@" .. commit_sha:sub(1, COMMIT_SHA_SHORT_LENGTH)
      break
    elseif pattern == "(%w+)@(%x+)" and text:match("^(%w+)@(%x+)$") then
      local user, sha = text:match("^(%w+)@(%x+)$")
      if repository_name and sha:len() >= COMMIT_SHA_MIN_LENGTH and sha:len() <= COMMIT_SHA_FULL_LENGTH then
        local repo_part = repository_name:match("/(.+)")
        if repo_part then
          repo = user .. "/" .. repo_part
          commit_sha = sha
          short_link = user .. "@" .. sha:sub(1, COMMIT_SHA_SHORT_LENGTH)
          break
        end
      end
    end
  end

  if not commit_sha then
    local all_platform_names = platforms.get_all_platform_names()
    for _, platform_name in ipairs(all_platform_names) do
      local platform_config = platforms.get_platform_config(platform_name)
      if platform_config then
        local platform_base_url = platform_config.default_url
        local escaped_platform_url = utils.escape_pattern(platform_base_url)
        local url_pattern = '^' .. escaped_platform_url .. '/([^/]+/[^/]+)/%-?/?commits?/(%x+)'
        if text:match(url_pattern) then
          repo, commit_sha = text:match(url_pattern)
          if commit_sha:len() >= COMMIT_SHA_MIN_LENGTH then
            if repo == repository_name then
              short_link = commit_sha:sub(1, COMMIT_SHA_SHORT_LENGTH)
            else
              short_link = repo .. '@' .. commit_sha:sub(1, COMMIT_SHA_SHORT_LENGTH)
            end
            matched_platform = platform_name
            matched_base_url = platform_base_url
            config = platform_config
            break
          end
        end
      end
    end
  end

  if commit_sha and repo and commit_sha:len() >= COMMIT_SHA_MIN_LENGTH then
    local url_format = config.url_formats.commit
    local uri = matched_base_url .. url_format:gsub("{repo}", repo):gsub("{sha}", commit_sha)
    return create_platform_link(short_link, uri, matched_platform), matched_platform, matched_base_url
  end

  return nil, nil, nil
end

--- Main Git hosting processing function
--- Attempts to convert string elements into Git hosting links by trying different patterns
--- @param elem pandoc.Str The string element to process
--- @return pandoc.Str|pandoc.Link The original element or a Git hosting link
local function process_gitlink(elem)
  if not platform or not base_url or utils.is_empty(platform) then
    return elem
  end

  local link = nil

  if link == nil then
    link = process_issues_and_mrs(elem, platform, base_url)
  end

  if link == nil then
    link = process_commits(elem, platform, base_url)
  end

  if link == nil then
    link = process_users(elem, platform)
  end

  if link == nil then
    return elem
  else
    return link
  end
end

--- Process inline elements for Bitbucket multi-word patterns
--- @param elem table Block element containing inline content
--- @return table The modified element
local function process_inlines(elem)
  if elem.content and platform == "bitbucket" then
    elem.content = bitbucket.process_inlines(elem.content, base_url, repository_name, create_platform_link)
  end
  return elem
end

--- Process Link elements to shorten URLs that are used as link text
--- @param elem pandoc.Link The link element to process
--- @return pandoc.Link The original or modified link
local function process_link(elem)
  -- Only process links where the text is the same as the URL (auto-generated links)
  local link_text = pandoc.utils.stringify(elem.content)
  local link_target = elem.target

  -- If the link text equals the target URL, try to shorten it
  if link_text == link_target then
    -- Create a temporary Str element to use existing processing logic
    local temp_str = pandoc.Str(link_text)
    local result = process_gitlink(temp_str)

    -- If process_gitlink returned a link, use its content as the new link text
    if pandoc.utils.type(result) == "Link" then
      return result
    end
  end

  return elem
end

--- Pandoc filter configuration
--- Defines the order of filter execution:
--- 1. Extract references from the document
--- 2. Get repository information from metadata
--- 3. Process inline containers for Bitbucket multi-word patterns
--- 4. Process link elements to shorten URLs used as link text
--- 5. Process string elements for Git hosting patterns
--- 6. Process citations for Git hosting mentions
return {
  { Pandoc = get_references },
  { Meta = get_repository },
  { Plain = process_inlines, Para = process_inlines },
  { Link = process_link },
  { Str = process_gitlink },
  { Cite = process_mentions }
}
