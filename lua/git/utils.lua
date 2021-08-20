local M = {}

local function starts(string, start)
  return string.sub(string, 1, string.len(start)) == start
end

function M.split(s, delimiter)
  local result = {}
  for match in (s .. delimiter):gmatch("(.-)" .. delimiter) do
    table.insert(result, match)
  end

  return result
end

function M.run_git_cmd(cmd)
  local cmd_result = vim.fn.system(cmd)
  if cmd_result == nil or starts(cmd_result, "fatal:") then
    return nil
  end

  return cmd_result
end

function M.log(message)
  vim.notify("[git] " .. message)
end

function M.get_git_repo()
  local fpath = vim.api.nvim_buf_get_name(0)
  if fpath == "" then
    return ""
  end

  return vim.fn.finddir(".git/..", fpath .. ";")
end

return M
