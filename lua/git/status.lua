local Job = require "plenary.job"
local utils = require "git.utils"
local git = require "git.utils.git"

local status_state = {
  untracked = {},
  unstaged = {},
  staged = {},
  output = {},
}

local M = {}

local function add_blankline()
  table.insert(status_state.output, "")
end

local function add_header(key, value)
  local line = key .. ": " .. value
  table.insert(status_state.output, line)
end

local function add_section(section_name, items)
  if #items == 0 then
    return
  end

  table.insert(status_state.output, section_name .. " (" .. tostring(#items) .. ")")
  for _, item in ipairs(items) do
    table.insert(status_state.output, item.status .. " " .. item.file)
  end

  add_blankline()
end

local function query_log(refspec, limit)
  local git_root = git.get_git_repo()
  if git_root == "" then
    return nil
  end

  local lines_string = ""
  local stderr = {}
  local stdout, _ = Job:new({
    command = "git",
    args = { "log", "-n", limit, "--pretty=format:%h%x09%s", refspec, "--" },
    cwd = git_root,
    on_stderr = function(_, data)
      table.insert(stderr, data)
    end,
  }):sync()

  if not vim.tbl_isempty(stderr) then
    return {}
  end

  return vim.tbl_map(function(line)
    local line_components = utils.split(line, "\t")

    return line_components[1] .. " " .. line_components[2]
  end, stdout)
end

local function add_log_section(section_name, refspec)
  local limit = 256
  local lines = query_log(refspec, limit)

  if #lines == 0 then
    return
  end

  table.insert(status_state.output, section_name .. " (" .. tostring(#lines) .. ")")
  for _, log in ipairs(lines) do
    table.insert(status_state.output, log)
  end
end

local function clear_state()
  status_state.untracked = {}
  status_state.unstaged = {}
  status_state.staged = {}
  status_state.output = {}
end

local function render(lines, open_new_buffer)
  while #lines > 0 and string.find(lines[1], "^%l+:") do
    table.remove(lines, 1)
  end

  if open_new_buffer then
    vim.api.nvim_command "tabedit"
  end

  local head = vim.fn.matchstr(lines[1], [[^## \zs\S\+\ze\%($\| \[\)]])
  local branch = ""
  local pull = ""

  if utils.contains(head, "...") then
    local head_pull = vim.fn.split(head, [[\.\.\.]])
    head = head_pull[1]
    pull = head_pull[2]
    branch = head
  elseif head == "HEAD" or head == "" then
    --FIXME: Is this correct?
    head = git.get_current_branch_name()
    branch = ""
  else
    branch = head
  end

  local status_buf = vim.api.nvim_get_current_buf()

  -- clear status state
  clear_state()

  for _, line in pairs(lines) do
    if string.sub(line, 3, 3) == " " then
      local file = string.sub(line, 4, -1)

      if vim.api.nvim_eval(string.format("'%s' !~# '[ ?!#]'", string.sub(line, 1, 1))) ~= 0 then
        table.insert(status_state.staged, { file = file, status = string.sub(line, 1, 1) })
      end

      if utils.starts_with(line, "??") then
        table.insert(status_state.untracked, { file = file, status = string.sub(line, 2, 2) })
      elseif vim.api.nvim_eval(string.format("'%s' !~# '[ !#]'", string.sub(line, 2, 2))) ~= 0 then
        table.insert(status_state.unstaged, { file = file, status = string.sub(line, 2, 2) })
      end
    end
  end

  add_header("Head", head)
  add_header("Merge", branch)
  add_blankline()
  add_section("Untracked", status_state.untracked)
  add_section("Unstaged", status_state.unstaged)
  add_section("Staged", status_state.staged)

  if pull ~= "" then
    add_log_section("Unpulled from " .. pull, head .. ".." .. pull)
  end

  vim.api.nvim_buf_set_option(status_buf, "modifiable", true)
  vim.api.nvim_buf_set_lines(status_buf, 0, -1, true, status_state.output)
  vim.api.nvim_buf_set_option(status_buf, "modifiable", false)

  vim.api.nvim_buf_set_option(status_buf, "buftype", "nofile")
  vim.api.nvim_buf_set_option(status_buf, "bufhidden", "delete")

  -- Keymaps
  local options = {
    noremap = true,
    silent = true,
    expr = false,
  }
  vim.api.nvim_buf_set_keymap(0, "n", "q", "<CMD>q<CR>", options)
  vim.api.nvim_buf_set_keymap(0, "n", "<space>", "<CMD>lua require('git.status').toggle_status()<CR>", options)
  vim.api.nvim_buf_set_keymap(0, "n", "r", "<CMD>lua require('git.status').refresh<CR>", options)
end

local function on_refresh_done(lines)
  render(lines, false)
end

local function on_status_done(lines)
  render(lines, true)
end

local function get_status_cmd()
  local git_root = git.get_git_repo()
  if git_root == "" then
    return nil
  end

  return "git -C " .. git_root .. " --no-optional-locks status --porcelain -b"
end

local function refresh()
  local status_cmd = get_status_cmd()
  if status_cmd == nil then
    return
  end

  utils.jobstart(status_cmd, on_refresh_done)
end

local function on_cmd_done(lines)
  refresh()
end

local function contains_file(files, file)
  for _, f in ipairs(files) do
    if f.file == file then
      return true
    end
  end

  return false
end

function M.toggle_status()
  local line = vim.api.nvim_get_current_line()
  if line == nil or line == "" then
    return
  end
  local git_root = git.get_git_repo()
  if git_root == "" then
    return
  end

  local cmd = ""
  if utils.starts_with(line, "Unstaged ") then
    cmd = "git -C " .. git_root .. " add -u"
  elseif utils.starts_with(line, "Untracked ") then
    cmd = "git -C " .. git_root .. " add ."
  elseif utils.starts_with(line, "Staged ") then
    cmd = "git -C " .. git_root .. " reset -q"
  elseif utils.contains(line, " ") then
    local file = utils.split(line, " ")[2]
    --FIXME: I know that this is not a good way to find the toggle command for the current line
    -- I can do better, however for sake of simplicity I would like brute force to find the appropriate cmd
    -- The git status files size is not large, I don't think it bring a big impact to the plugin's performance
    if contains_file(status_state.staged, file) then
      cmd = "git -C " .. git_root .. " reset -q -- " .. file
    elseif contains_file(status_state.unstaged, file) then
      cmd = "git -C " .. git_root .. " add -A -- " .. file
    elseif contains_file(status_state.untracked, file) then
      cmd = "git -C " .. git_root .. " add -- " .. file
    end
  end

  if cmd == "" then
    return
  end

  utils.jobstart(cmd, on_cmd_done)
end

function M.open()
  local status_cmd = get_status_cmd()
  if status_cmd == nil then
    return
  end

  utils.jobstart(status_cmd, on_status_done)
end

return M
