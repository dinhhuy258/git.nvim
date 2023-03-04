local M = {}

local path_separator = package.config:sub(1, 1)

function M.remove_trailing(path)
  local p, _ = path:gsub(path_separator .. "$", "")

  return p
end

function M.join(paths)
  return table.concat(vim.tbl_map(M.remove_trailing, paths), path_separator)
end

function M.shorten(path)
  path = M.remove_trailing(path)
  local path_separator_count = select(2, string.gsub(path, path_separator, ""))
  for _ = 0, path_separator_count do
    path = path:gsub(
      string.format("([^%s])[^%s]+%%%s", path_separator, path_separator, path_separator),
      "%1" .. path_separator,
      1
    )
  end

  return path
end

return M
