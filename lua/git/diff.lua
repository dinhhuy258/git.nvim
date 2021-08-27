local utils = require "git.utils"

local M = {}

local diff_state = {
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
  vim.api.nvim_command "autocmd BufDelete <buffer> lua require('git.diff').diff_quit()"
end

function M.diff_quit()
  vim.fn.delete(diff_state.temp_file)
end

function M.diff()
  local fpath = vim.api.nvim_buf_get_name(0)
  if fpath == "" or fpath == nil then
    return
  end

  local git_root = utils.get_git_repo()
  if git_root == "" then
    return
  end

  local file_content_cmd = "git -C "
    .. git_root
    .. " --literal-pathspecs --no-pager show HEAD:"
    .. vim.fn.fnamemodify(vim.fn.expand "%", ":~:.")

  local lines = {}

  local function on_event(_, data, event)
    if event == "stdout" or event == "stderr" then
      -- TODO: Handle error
      data = utils.handle_job_data(data)
      if not data then
        return
      end

      for i = 1, #data do
        table.insert(lines, data[i])
      end
    end

    if event == "exit" then
      on_get_file_content_done(lines)
    end
  end

  vim.notify(file_content_cmd)
  vim.fn.jobstart(file_content_cmd, {
    on_stderr = on_event,
    on_stdout = on_event,
    on_exit = on_event,
    stdout_buffered = true,
    stderr_buffered = true,
  })
end

return M
