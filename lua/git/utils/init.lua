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

function M.handle_job_data(data)
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

function M.log(message)
  vim.notify("[git] " .. message)
end

function M.jobstart(cmd, on_finish)
  local has_error = false
  local lines = {}

  local function on_event(_, data, event)
    if event == "stdout" then
      data = M.handle_job_data(data)
      if not data then
        return
      end

      for i = 1, #data do
        table.insert(lines, data[i])
      end
    elseif event == "stderr" then
      data = M.handle_job_data(data)
      if not data then
        return
      end

      has_error = true
      local error_message = ""
      for _, line in ipairs(data) do
        error_message = error_message .. line
      end
      M.log("Error during running a job: " .. error_message)
    elseif event == "exit" then
      if not has_error then
        on_finish(lines)
      end
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

function M.async_cmd(cmd, args, callback)
  local stdout = vim.loop.new_pipe(false)
  local stderr = vim.loop.new_pipe(false)
  local handle

  handle = vim.loop.spawn(cmd, { args = args, stdio = { nil, stdout, stderr }, cwd = vim.loop.cwd() }, function()
    if callback then
      callback()
    end

    vim.loop.read_stop(stdout)
    vim.loop.read_stop(stderr)
    stdout:close()
    stderr:close()
    handle:close()
  end)

  vim.loop.read_start(stdout, function(err, _)
    if err ~= nil then
      vim.schedule(function()
        -- M.echo_warning(err)
      end)
    end
  end)

  vim.loop.read_start(stderr, function(err, data)
    if data ~= nil then
      vim.schedule(function()
        -- M.echo_warning(data)
      end)
    end

    if err ~= nil then
      vim.schedule(function()
        -- M.echo_warning(err)
      end)
    end
  end)
end

return M
