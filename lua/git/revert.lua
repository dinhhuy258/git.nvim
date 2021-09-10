local utils = require "git.utils"
local git = require "git.utils.git"

local M = {}

function M.revert()
  local git_root, _ = git.get_repo_info()
  local git_log_cmd = "git -C "
    .. git_root
    .. ' --no-pager -c diff.context=0 -c diff.noprefix=false log --no-color --no-ext-diff --pretty="format:%H %s"'

  local function on_get_log_done(lines)
    if #lines <= 0 then
      return
    end

    vim.fn.setqflist({}, " ", {
      title = "Revert",
      lines = lines,
      -- efm = vim.api.nvim_buf_get_option(bufnr, "errorformat"),
    })

    vim.cmd("copen")
  end

  utils.start_job(git_log_cmd, on_get_log_done)
end

return M
