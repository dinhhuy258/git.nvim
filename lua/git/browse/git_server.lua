local git = require "git.utils.git"
local path = require "git.utils.path"
local log = require "git.utils.log"
local utils = require "git.utils"

local GitServer = {}

function GitServer.new(git_url, git_path, git_dir, branch)
  local self = setmetatable({}, { __index = GitServer })
  self.git_url = git_url
  self.path = git_path
  self.git_dir = git_dir
  self.branch = branch

  return self
end

function GitServer._open_url(url)
  if vim.fn.has "win16" == 1 or vim.fn.has "win32" == 1 or vim.fn.has "win64" == 1 then
    vim.fn.system("start cmd /cstart /b " .. url)
  elseif vim.fn.has "mac" == 1 or vim.fn.has "macunix" == 1 or vim.fn.has "gui_macvim" == 1 then
    vim.fn.system('open "' .. url .. '"')
  else
    vim.fn.system('xdg-open "' .. url .. '" &> /dev/null &')
  end
end

function GitServer:_open(visual_mode)
  local current_file = vim.fn.expand "%:h"
  if current_file ~= nil and current_file ~= "" then
    local git_root = git.get_git_repo()
    local absolute_path = vim.fn.expand "%:p"
    local relative_path = vim.fn.fnamemodify(vim.fn.expand "%", ":~:.")
    -- TODO: moving starts_with method to utils/string.lua
    if utils.starts_with(absolute_path, git_root) then
      relative_path = absolute_path:sub(#git_root + 1)
    end

    if not visual_mode then
      GitServer._open_url(path.join { self.git_url, self.path, "blob", self.branch, relative_path })

      return
    end

    -- visual mode
    local start_line = vim.fn.getpos("'<")[2]
    local end_line = vim.fn.getpos("'>")[2]

    self:_open_visual_mode(relative_path, start_line, end_line)
  else
    GitServer._open_url(path.join { self.git_url, self.path, "tree", self.branch })
  end
end

function GitServer:_get_latest_commit()
  local latest_commit_hash =
    git.run_git_cmd("git -C " .. self.git_dir .. " rev-parse " .. self.branch .. ' | tr -d "\n"')
  if latest_commit_hash == nil or latest_commit_hash == "" then
    log.error("Failed to get the lastest commit from branch: " .. self.branch)

    return nil
  end

  return latest_commit_hash
end

function GitServer:open(visual_mode)
  -- this function should be implemented in the derived classes
end

function GitServer:_open_visual_mode(relative_path, start_line, end_line)
  -- this function should be implemented in the derived classes
end

function GitServer:open_pull_request()
  -- this function should be implemented in the derived classes
end

function GitServer:create_pull_request(target_branch)
  -- this function should be implemented in the derived classes
end

return GitServer
