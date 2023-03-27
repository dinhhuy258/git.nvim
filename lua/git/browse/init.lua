local log = require "git.utils.log"
local config = require("git.config").config
local GitServerFactory = require "git.browse.git_server_factory"

local M = {}

function M.open(visual_mode)
  log.info "Opening Git repository..."

  local git_server = GitServerFactory.get_git_server()
  if git_server == nil then
    return
  end

  git_server:open(visual_mode)
end

function M.pull_request()
  log.info "Opening current pull request..."

  local git_server = GitServerFactory.get_git_server()
  if git_server == nil then
    return
  end

  git_server:open_pull_request()
end

function M.create_pull_request(target_branch)
  log.info "Creating pull request..."

  local git_server = GitServerFactory.get_git_server()
  if git_server == nil then
    return
  end

  local git_target_branch = config.target_branch
  if target_branch ~= nil and target_branch ~= "" then
    git_target_branch = target_branch
  end

  git_server:create_pull_request(git_target_branch)
end

return M
