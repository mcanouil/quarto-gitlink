--- Damage the QUARTO_EXECUTE_INFO file before gitlink reads it, in the way
--- named by the `break-execute-info` metadata key. Any other value, such as
--- `none`, leaves the file as it is.
local CONTENTS = {
  empty = '',
  ['invalid-json'] = 'not json',
  ['no-metadata'] = '{"format": {}}',
}

function Meta(meta)
  local mode = meta['break-execute-info'] and pandoc.utils.stringify(meta['break-execute-info'])
  local path = os.getenv('QUARTO_EXECUTE_INFO')
  if not mode or not path then
    return nil
  end
  if mode == 'unreadable' then
    os.remove(path)
  elseif CONTENTS[mode] then
    local file = assert(io.open(path, 'w'))
    file:write(CONTENTS[mode])
    file:close()
  end
  return nil
end
