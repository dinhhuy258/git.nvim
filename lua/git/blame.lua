local M = {}

local function create_blame_win()
  vim.api.nvim_command "topleft vnew"
  local win = vim.api.nvim_get_current_win()
  local buf = vim.api.nvim_get_current_buf()

  -- vim.api.nvim_buf_set_name(buf, "GBlame #" .. buf)
  vim.api.nvim_buf_set_option(buf, "buftype", "nofile")
  vim.api.nvim_buf_set_option(buf, "swapfile", false)
  vim.api.nvim_buf_set_option(buf, "bufhidden", "wipe")
  vim.api.nvim_buf_set_option(buf, "filetype", "git.nvim")
  vim.api.nvim_buf_set_option(buf, "buflisted", false)

  vim.api.nvim_win_set_option(win, "wrap", false)
  vim.api.nvim_win_set_width(win, 40)
end

function M.blame()
  create_blame_win()
end

return M
