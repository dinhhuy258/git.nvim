local Loclist = require "git.status.components.loclist"
local path = require "git.utils.path"
local log = require "git.utils.log"
local utils = require "git.utils"
local has_devicons, devicons = pcall(require, "nvim-web-devicons")

local M = {}
local loclist = Loclist:new {}
loclist:add_group "Staged"
loclist:add_group "Unstaged"
loclist:add_group "Unmerged"
loclist:add_group "Untracked"

local loclist_items = {}
local finished = 0
local expected_job_count = 4

local function parse_git_diff(group, line)
  local t = vim.split(line, "\t")
  local added, removed, filepath = t[1], t[2], t[3]
  local extension = filepath:match "^.+%.(.+)$"
  local fileicon = ""
  local filehighlight = "SidebarNvimGitStatusFileIcon"

  if has_devicons and devicons.has_loaded() then
    local icon, highlight = devicons.get_icon(filepath, extension)

    if icon then
      fileicon = icon
      filehighlight = highlight
    end
  end

  if filepath ~= "" then
    loclist:open_group(group)

    table.insert(loclist_items, {
      group = group,
      left = {
        {
          text = fileicon .. " ",
          hl = filehighlight,
        },
        {
          text = path.shorten(filepath) .. " ",
          hl = "SidebarNvimGitStatusFileName",
        },
        {
          text = added,
          hl = "SidebarNvimGitStatusDiffAdded",
        },
        {
          text = ", ",
        },
        {
          text = removed,
          hl = "SidebarNvimGitStatusDiffRemoved",
        },
      },
      filepath = filepath,
    })
  end
end

local function parse_git_status(group, line)
  local striped = line:match "^%s*(.-)%s*$"
  local status = striped:sub(0, 2)
  local filepath = striped:sub(3, -1):match "^%s*(.-)%s*$"
  local extension = filepath:match "^.+%.(.+)$"

  if status == "??" then
    local fileicon = ""

    if has_devicons and devicons.has_loaded() then
      local icon = devicons.get_icon_color(filepath, extension)
      if icon then
        fileicon = icon
      end
    end

    loclist:open_group(group)

    table.insert(loclist_items, {
      group = group,
      left = {
        {
          text = fileicon .. " ",
          hl = "SidebarNvimGitStatusFileIcon",
        },
        {
          text = path.shorten(filepath),
          hl = "SidebarNvimGitStatusFileName",
        },
      },
      filepath = filepath,
    })
  end
end

local NAMESPACE_ID = vim.api.nvim_create_namespace "GitHighlights"

--- add the highlights
---@param bufnr integer
---@param highlights table
local function _add_highlights(bufnr, highlights)
  vim.api.nvim_buf_clear_namespace(bufnr, NAMESPACE_ID, 0, -1)

  for _, highlight in ipairs(highlights) do
    vim.api.nvim_buf_add_highlight(
      bufnr,
      NAMESPACE_ID,
      highlight.hl_group,
      highlight.line,
      highlight.col_start,
      highlight.col_end
    )
  end
end

local function render()
  local lines = {}
  local hl = {}

  loclist:draw({
    width = 80,
  }, lines, hl)

  -- local bufnr = vim.api.nvim_get_current_buf()
  -- if bufnr ~= status_state.bufnr then
  vim.api.nvim_command "tabedit"
  -- end
  local status_buf = vim.api.nvim_get_current_buf()
  local bufnr = status_buf
  -- status_state.bufnr = status_buf

  vim.api.nvim_buf_set_lines(status_buf, 0, -1, true, lines)
  _add_highlights(status_buf, hl)

  local options = { noremap = true, silent = true, nowait = true, buffer = bufnr }

  vim.keymap.set("n", "s", function()
    local line = vim.fn.line "."
    local location = loclist:get_location_at(line)
    if location == nil then
      return
    end

    utils.async_cmd("git", { "add", location.filepath }, function()
      -- async_update_debounced:call()
    end)
  end, options)

  vim.keymap.set("n", "u", function()
    local line = vim.fn.line "."
    local location = loclist:get_location_at(line)
    if location == nil then
      return
    end

    utils.async_cmd("git", { "restore", "--staged", location.filepath }, function()
      -- async_update_debounced:call()
    end)
  end, options)
end

local function async_cmd(group, command, args, parse_fn)
  local stdout = vim.loop.new_pipe(false)
  local stderr = vim.loop.new_pipe(false)

  local handle
  handle = vim.loop.spawn(command, { args = args, stdio = { nil, stdout, stderr }, cwd = vim.loop.cwd() }, function()
    finished = finished + 1

    if finished == expected_job_count then
      loclist:set_items(loclist_items, { remove_groups = false })
      -- render
      vim.schedule(function()
        render()
      end)
    end

    vim.loop.read_stop(stdout)
    vim.loop.read_stop(stderr)
    stdout:close()
    stderr:close()
    handle:close()
  end)

  vim.loop.read_start(stdout, function(err, data)
    if data == nil then
      return
    end

    for _, line in ipairs(vim.split(data, "\n")) do
      if line ~= "" then
        parse_fn(group, line)
      end
    end

    if err ~= nil then
      vim.schedule(function()
        log.warn(err)
      end)
    end
  end)

  vim.loop.read_start(stderr, function(err, data)
    if data == nil then
      return
    end

    if err ~= nil then
      vim.schedule(function()
        log.warn(err)
      end)
    end
  end)
end

function M.open()
  loclist_items = {}
  finished = 0

  async_cmd("Staged", "git", { "diff", "--numstat", "--staged", "--diff-filter=u" }, parse_git_diff)
  async_cmd("Unstaged", "git", { "diff", "--numstat", "--diff-filter=u" }, parse_git_diff)
  async_cmd("Unmerged", "git", { "diff", "--numstat", "--diff-filter=U" }, parse_git_diff)
  async_cmd("Untracked", "git", { "status", "--porcelain" }, parse_git_status)
end

return M
