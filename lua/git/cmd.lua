local M = {}

function M.cmd(cmd)
  local winnr = vim.fn.win_getid()
  local bufnr = vim.api.nvim_win_get_buf(winnr)

  vim.cmd [[setl errorformat =%-G#\ %.%#]]
  local lines = { "" }
  local function on_event(_, data, event)
    if event == "stdout" or event == "stderr" then
      if data then
        vim.list_extend(lines, data)
      end
    end

    if event == "exit" then
      vim.fn.setqflist({}, " ", {
        title = "test",
        lines = lines,
        efm = vim.api.nvim_buf_get_option(bufnr, "errorformat"),
      })
      vim.api.nvim_command "doautocmd QuickFixCmdPost"
    end
    if #lines > 1 then
      vim.cmd "copen"
    end
  end

  vim.fn.jobstart(cmd, {
    on_stderr = on_event,
    on_stdout = on_event,
    on_exit = on_event,
    stdout_buffered = true,
    stderr_buffered = true,
  })
end

return M
