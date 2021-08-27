local M = {}

function M.starts_with(str, start)
  return str:sub(1, #start) == start
end

function M.end_with(str, ending)
  return ending == "" or str:sub(-#ending) == ending
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
  if cmd_result == nil or M.starts_with(cmd_result, "fatal:") then
    return nil
  end

  return cmd_result
end

function M.log(message)
  vim.notify("[git] " .. message)
end

function M.get_git_repo()
  local dir = vim.fn.trim(M.run_git_cmd('git rev-parse --show-toplevel'))
  local file = vim.fn.expand('%')

  if file == "" or file == "." or dir == "" then
    return ""
  else
    return dir
  end
end

M.handle_job_data = function(data)
  if not data then
    return nil
  end
  if data[#data] == "" then
    table.remove(data, #data)
  end
  if #data < 1 then
    return nil
  end
  return data
end

return M
