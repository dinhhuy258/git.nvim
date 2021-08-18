local blame_state = require("git.state").blame_state

local M = {}

local function on_blame_commit_done(commit_hash, lines)
  local temp_file = vim.fn.tempname()
  blame_state.temp_file = temp_file
  vim.fn.writefile(lines, temp_file)

  local win = vim.api.nvim_get_current_win()
  vim.api.nvim_win_close(win, true)

  vim.api.nvim_command("silent! e" .. temp_file)

  local buf = vim.api.nvim_get_current_buf()
  vim.api.nvim_buf_set_name(buf, commit_hash)
  vim.api.nvim_command "autocmd BufLeave <buffer> lua require('git.blame_commit').blame_commit_quit()"
end

function M.blame_commit_quit()
  local buf = vim.api.nvim_get_current_buf()
  vim.api.nvim_command(buf .. "bdelete")
  vim.fn.delete(blame_state.temp_file)
end

function M.blame_commit()
  local line = vim.fn.getline "."
  local commit = vim.fn.matchstr(line, [[^\^\=[?*]*\zs\x\+]])
  if string.match(commit, "^0+$") then
    vim.notify("Not Committed Yet")
    return
  end

  local commit_hash = vim.fn.system("git --literal-pathspecs rev-parse --verify " .. commit .. " --")
  commit_hash = string.gsub(commit_hash, "\n", "")
  local diff_cmd = "git --literal-pathspecs --no-pager show --no-color --pretty=format:%b "
    .. commit_hash
    .. " "
    .. blame_state.file

  local lines = {}
  local function on_event(_, data, event)
    if event == "stdout" or event == "stderr" then
      if data then
        for i = 1, #data do
          if data[i] ~= "" then
            table.insert(lines, data[i])
          end
        end
      end
    end

    if event == "exit" then
      on_blame_commit_done(commit_hash, lines)
    end
  end

  vim.fn.jobstart(diff_cmd, {
    on_stderr = on_event,
    on_stdout = on_event,
    on_exit = on_event,
    stdout_buffered = true,
    stderr_buffered = true,
  })
end

return M
