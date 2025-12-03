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

--- Platform Configuration Module
--- Manages platform-specific configurations for Git hosting services
--- @module platforms
--- @author Mickaël Canouil
--- @version 1.0.0

local platforms_module = {}

-- ============================================================================
-- CONFIGURATION STORAGE
-- ============================================================================

--- @type table<string, table> Platform configurations cache
local platform_configs = nil

--- @type table<string, table> Custom platform configurations
local custom_platforms = {}

-- ============================================================================
-- HELPER FUNCTIONS
-- ============================================================================

--- Check if a value is empty or nil
--- @param val any The value to check
--- @return boolean True if the value is nil or empty, false otherwise
local function is_empty(val)
  return val == nil or val == ''
end

--- Convert YAML value to Lua table structure
--- @param yaml_value any The YAML value to convert
--- @return any The converted value
local function convert_yaml_value(yaml_value)
  local yaml_type = pandoc.utils.type(yaml_value)

  if yaml_type == 'Inlines' or yaml_type == 'Blocks' then
    return pandoc.utils.stringify(yaml_value)
  elseif yaml_type == 'List' then
    local result = {}
    for i = 1, #yaml_value do
      result[i] = convert_yaml_value(yaml_value[i])
    end
    return result
  elseif type(yaml_value) == 'table' then
    local result = {}
    for key, value in pairs(yaml_value) do
      result[key] = convert_yaml_value(value)
    end
    return result
  else
    return yaml_value
  end
end

-- ============================================================================
-- CONFIGURATION LOADING
-- ============================================================================

--- Load platform configurations from YAML file
--- @param yaml_path string|nil Optional path to custom YAML file
--- @return table<string, table>|nil The platform configurations or nil on error
--- @usage local configs = platforms_module.load_platforms('custom-platforms.yml')
local function load_platforms(yaml_path)
  local config_path = yaml_path or quarto.utils.resolve_path('platforms.yml')

  -- Check if file exists
  local file = io.open(config_path, 'r')
  if not file then
    return nil
  end
  local content = file:read('*all')
  file:close()

  -- Parse YAML using Pandoc
  local success, result = pcall(function()
    local meta = pandoc.read('---\n' .. content .. '\n---', 'markdown').meta
    if meta and meta.platforms then
      return convert_yaml_value(meta.platforms)
    end
    return nil
  end)

  if success and result then
    return result
  end

  return nil
end

--- Initialise platform configurations
--- @param yaml_path string|nil Optional path to custom YAML file
--- @return boolean True if initialisation was successful, false otherwise
--- @usage platforms_module.initialise('custom-platforms.yml')
function platforms_module.initialise(yaml_path)
  if platform_configs and not yaml_path then
    return true
  end

  local loaded_configs = load_platforms(yaml_path)

  if not loaded_configs then
    if not platform_configs then
      platform_configs = {}
    end
    return false
  end

  if platform_configs and yaml_path then
    for name, config in pairs(loaded_configs) do
      custom_platforms[name] = config
    end
  else
    platform_configs = loaded_configs
  end

  return true
end

-- ============================================================================
-- PUBLIC API
-- ============================================================================

--- Get platform configuration by name
--- @param platform_name string The platform name
--- @return table|nil The platform configuration or nil if not found
--- @usage local config = platforms_module.get_platform_config('github')
function platforms_module.get_platform_config(platform_name)
  if not platform_configs then
    platforms_module.initialise()
  end

  local name_lower = platform_name:lower()

  if custom_platforms[name_lower] then
    return custom_platforms[name_lower]
  end

  if platform_configs and platform_configs[name_lower] then
    return platform_configs[name_lower]
  end

  return nil
end

--- Get all available platform names
--- @return table<integer, string> List of available platform names
--- @usage local platforms = platforms_module.get_all_platform_names()
function platforms_module.get_all_platform_names()
  if not platform_configs then
    platforms_module.initialise()
  end

  local names = {}

  -- Add loaded platform names
  if platform_configs then
    for name, _ in pairs(platform_configs) do
      table.insert(names, name)
    end
  end

  -- Add custom platform names
  for name, _ in pairs(custom_platforms) do
    if not platform_configs or not platform_configs[name] then
      table.insert(names, name)
    end
  end

  table.sort(names)
  return names
end

--- Register a custom platform configuration
--- @param platform_name string The platform name
--- @param config table The platform configuration
--- @return boolean True if registration was successful, false otherwise
--- @usage platforms_module.register_custom_platform('forgejo', {...})
function platforms_module.register_custom_platform(platform_name, config)
  if not platform_name or not config then
    return false
  end

  -- Validate required fields
  if not config.default_url then
    return false
  end

  if not config.patterns or not config.url_formats then
    return false
  end

  local name_lower = platform_name:lower()
  custom_platforms[name_lower] = config

  return true
end

--- Load custom platform from YAML string
--- @param yaml_string string The YAML string containing platform configuration
--- @param platform_name string The platform name to register
--- @return boolean True if registration was successful, false otherwise
--- @usage platforms_module.load_custom_platform_from_yaml(yaml_str, 'forgejo')
function platforms_module.load_custom_platform_from_yaml(yaml_string, platform_name)
  if is_empty(yaml_string) or is_empty(platform_name) then
    return false
  end

  local success, result = pcall(function()
    local meta = pandoc.read('---\n' .. yaml_string .. '\n---', 'markdown').meta
    if meta and meta.platforms and meta.platforms[platform_name] then
      return convert_yaml_value(meta.platforms[platform_name])
    end
    return nil
  end)

  if success and result then
    return platforms_module.register_custom_platform(platform_name, result)
  end

  return false
end

--- Clear all custom platform configurations
--- @return nil
--- @usage platforms_module.clear_custom_platforms()
function platforms_module.clear_custom_platforms()
  custom_platforms = {}
end

--- Check if a platform is available
--- @param platform_name string The platform name
--- @return boolean True if the platform is available, false otherwise
--- @usage local available = platforms_module.is_platform_available('github')
function platforms_module.is_platform_available(platform_name)
  local name_lower = platform_name:lower()
  return platforms_module.get_platform_config(name_lower) ~= nil
end

-- ============================================================================
-- MODULE EXPORT
-- ============================================================================

return platforms_module
