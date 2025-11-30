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

--- MC Bitbucket - Bitbucket-specific functionality for gitlink extension
--- @module bitbucket
--- @author Mickaël Canouil
--- @version 1.0.0

local bitbucket_module = {}

-- ============================================================================
-- BITBUCKET MULTI-WORD PATTERN PROCESSING
-- ============================================================================

--- Process Bitbucket-style multi-word patterns in inline sequences
--- This function handles patterns like "issue #123" and "pull request #456"
--- according to https://support.atlassian.com/bitbucket-cloud/docs/markup-comments/
--- @param inlines table List of inline elements
--- @param base_url string The base URL for the Bitbucket instance
--- @param repository_name string|nil The repository name (e.g., "owner/repo")
--- @param utils table The utils module for creating links
--- @return table Modified list of inline elements
--- @usage local result = bitbucket_module.process_inlines(inlines, "https://bitbucket.org", "owner/repo", utils)
function bitbucket_module.process_inlines(inlines, base_url, repository_name, utils)
  local result = {}
  local i = 1

  while i <= #inlines do
    local matched = false

    -- Try to match "issue #123" pattern
    if i + 2 <= #inlines then
      local elem1, elem2, elem3 = inlines[i], inlines[i+1], inlines[i+2]
      if elem1.t == "Str" and elem1.text == "issue" and
         elem2.t == "Space" and
         elem3.t == "Str" and elem3.text:match("^#(%d+)$") then
        local number = elem3.text:match("^#(%d+)$")
        local uri
        if repository_name then
          uri = base_url .. "/" .. repository_name .. "/issues/" .. number
        else
          return inlines -- Cannot create link without repository name
        end
        local link = utils.create_link("issue " .. elem3.text, uri)
        if link then
          table.insert(result, link)
          i = i + 3
          matched = true
        end
      end
    end

    -- Try to match "issue owner/repo#123" pattern
    if not matched and i + 2 <= #inlines then
      local elem1, elem2, elem3 = inlines[i], inlines[i+1], inlines[i+2]
      if elem1.t == "Str" and elem1.text == "issue" and
         elem2.t == "Space" and
         elem3.t == "Str" and elem3.text:match("^([^/]+/[^/#]+)#(%d+)$") then
        local repo, number = elem3.text:match("^([^/]+/[^/#]+)#(%d+)$")
        local uri = base_url .. "/" .. repo .. "/issues/" .. number
        local link = utils.create_link("issue " .. elem3.text, uri)
        if link then
          table.insert(result, link)
          i = i + 3
          matched = true
        end
      end
    end

    -- Try to match "pull request #456" pattern
    if not matched and i + 4 <= #inlines then
      local elem1, elem2, elem3, elem4, elem5 = inlines[i], inlines[i+1], inlines[i+2], inlines[i+3], inlines[i+4]
      if elem1.t == "Str" and elem1.text == "pull" and
         elem2.t == "Space" and
         elem3.t == "Str" and elem3.text == "request" and
         elem4.t == "Space" and
         elem5.t == "Str" and elem5.text:match("^#(%d+)$") then
        local number = elem5.text:match("^#(%d+)$")
        local uri
        if repository_name then
          uri = base_url .. "/" .. repository_name .. "/pull-requests/" .. number
        else
          return inlines -- Cannot create link without repository name
        end
        local link = utils.create_link("pull request " .. elem5.text, uri)
        if link then
          table.insert(result, link)
          i = i + 5
          matched = true
        end
      end
    end

    -- Try to match "pull request owner/repo#456" pattern
    if not matched and i + 4 <= #inlines then
      local elem1, elem2, elem3, elem4, elem5 = inlines[i], inlines[i+1], inlines[i+2], inlines[i+3], inlines[i+4]
      if elem1.t == "Str" and elem1.text == "pull" and
         elem2.t == "Space" and
         elem3.t == "Str" and elem3.text == "request" and
         elem4.t == "Space" and
         elem5.t == "Str" and elem5.text:match("^([^/]+/[^/#]+)#(%d+)$") then
        local repo, number = elem5.text:match("^([^/]+/[^/#]+)#(%d+)$")
        local uri = base_url .. "/" .. repo .. "/pull-requests/" .. number
        local link = utils.create_link("pull request " .. elem5.text, uri)
        if link then
          table.insert(result, link)
          i = i + 5
          matched = true
        end
      end
    end

    if not matched then
      table.insert(result, inlines[i])
      i = i + 1
    end
  end

  return result
end

-- ============================================================================
-- MODULE EXPORT
-- ============================================================================

return bitbucket_module
