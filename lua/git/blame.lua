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
  local fpath = vim.fn.expand('%:p')
  create_blame_win()
  vim.api.nvim_command('read!git --literal-pathspecs --no-pager -c blame.coloring=none -c blame.blankBoundary=false blame --show-number -- ' .. fpath)
--   vim.fn.jobstart(cmd, {
--     on_stderr = on_event,
--     on_stdout = on_event,
--     on_exit = on_event,
--     stdout_buffered = true,
--     stderr_buffered = true,
--   })
end

return M
