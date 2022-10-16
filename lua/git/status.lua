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

local function clear_state()
  status_state.untracked = {}
  status_state.unstaged = {}
  status_state.staged = {}
  status_state.output = {}
end

local function on_status_done(lines)
  while #lines > 0 and string.find(lines[1], "^%l+:") do
    table.remove(lines, 1)
  end

  -- open a new buffer
  vim.api.nvim_command "tabedit"
  local head = vim.fn.matchstr(lines[1], [[^## \zs\S\+\ze\%($\| \[\)]])
  local branch = ""

  if utils.contains(head, "...") then
    head = vim.fn.split(head, [[\.\.\.]])[1]
    branch = head
  elseif head == "HEAD" or head == "" then
    head = git.get_current_branch_name()
    branch = head
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

  vim.api.nvim_buf_set_lines(status_buf, 0, -1, true, status_state.output)
  vim.api.nvim_buf_set_option(status_buf, "modifiable", false)

  -- vim.api.nvim_buf_set_name(buf, "~/" .. buf_name)
  -- vim.api.nvim_buf_set_option(buf, "buftype", "nofile")
  -- vim.api.nvim_buf_set_option(buf, "bufhidden", "delete")
  -- vim.api.nvim_buf_set_option(buf, "modifiable", false)
  -- vim.api.nvim_command "autocmd BufDelete <buffer> lua require('git.diff').on_diff_quit()"
end

function M.open()
  local fpath = vim.api.nvim_buf_get_name(0)
  if fpath == "" or fpath == nil then
    return
  end

  local git_root = git.get_git_repo()
  if git_root == "" then
    return
  end

  local status_cmd = "git -C " .. git_root .. " --no-optional-locks status --porcelain -b"

  utils.jobstart(status_cmd, on_status_done)
end

return M
