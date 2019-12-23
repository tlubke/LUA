function get_siblings(file_path, file_name)
  -- returns a table of strings containing the full paths
  -- in the same directory as file_name, including file_name
  local escaped = function()
    return string.gsub(file_name, "[%p%c]", function(c)
      return string.format("%%%s", c) end)
  end
  local dir = string.gsub(file_path, escaped, "")
  local files = {}
  local temp = norns.state.data.."files.txt"
  
  os.execute('ls -1 '..dir..' > '..temp)
  
  local f = io.open(temp)
  if not f then return files end
  local k = 1
  for line in f:lines() do
    files[k] = dir..line
    k = k + 1
  end
  f:close()
  
  return files
end
