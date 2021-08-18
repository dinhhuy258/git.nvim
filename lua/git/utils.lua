local M = {}

function M.get_git_repo()
  local fpath = vim.api.nvim_buf_get_name(0)
  if fpath == "" then
    return ""
  end

  return vim.fn.finddir(".git/..", fpath .. ";")
end

return M
