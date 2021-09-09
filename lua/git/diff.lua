local utils = require "git.utils"
local git = require "git.utils.git"

local M = {}

local diff_state = {
  base_bufnr = nil,
  temp_file = nil,
}

local function on_get_file_content_done(lines)
  local buf_name = vim.fn.fnamemodify(vim.fn.expand "%", ":~:.")

  local temp_file = vim.fn.tempname()
  diff_state.temp_file = temp_file
  vim.fn.writefile(lines, temp_file)
  vim.api.nvim_command("leftabove keepalt vertical diffsplit" .. temp_file)

  local buf = vim.api.nvim_get_current_buf()
  vim.api.nvim_buf_set_name(buf, "~/" .. buf_name)
  vim.api.nvim_buf_set_option(buf, "buftype", "nofile")
  vim.api.nvim_buf_set_option(buf, "bufhidden", "delete")
  vim.api.nvim_buf_set_option(buf, "modifiable", false)
  vim.api.nvim_command "autocmd BufDelete <buffer> lua require('git.diff').on_diff_quit()"
end

function M.on_diff_quit()
  vim.fn.delete(diff_state.temp_file)
end

function M.close()
  if not vim.wo.diff then
    return
  end

  vim.api.nvim_command "diffoff"
  vim.api.nvim_command("buffer " .. diff_state.base_bufnr)
  vim.api.nvim_command "on"
end

function M.open(base)
  if vim.wo.diff then
    return
  end

  local fpath = vim.api.nvim_buf_get_name(0)
  if fpath == "" or fpath == nil then
    return
  end

  local git_root = git.get_git_repo()
  if git_root == "" then
    return
  end

  if base == nil or base == "" then
    base = "HEAD"
  end

  local file_content_cmd = "git -C "
    .. git_root
    .. string.format(" --literal-pathspecs --no-pager show %s:", base)
    .. vim.fn.fnamemodify(vim.fn.expand "%", ":~:.")

  local has_error = false
  local lines = {}

  local function on_event(_, data, event)
    if event == "stdout" then
      data = utils.handle_job_data(data)
      if not data then
        return
      end

      for i = 1, #data do
        table.insert(lines, data[i])
      end
    elseif event == "stderr" then
      data = utils.handle_job_data(data)
      if not data then
        return
      end

      has_error = true
      local error_message = ""
      for _, line in ipairs(data) do
        error_message = error_message .. line
      end
      utils.log("Failed to open git diff window: " .. error_message)
    elseif event == "exit" then
      if not has_error then
        on_get_file_content_done(lines)
      end
    end
  end

  diff_state.base_bufnr = vim.api.nvim_get_current_buf()

  vim.fn.jobstart(file_content_cmd, {
    on_stderr = on_event,
    on_stdout = on_event,
    on_exit = on_event,
    stdout_buffered = true,
    stderr_buffered = true,
  })
end

return M
