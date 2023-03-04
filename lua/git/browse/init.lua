local log = require "git.utils.log"
local config = require("git.config").config
local GitServerFactory = require "git.browse.git_server_factory"

local M = {}

function M.open(visual_mode)
  local git_server = GitServerFactory.get_git_server()
  if git_server == nil then
    return
  end

  log.info "Opening Git repository..."

  git_server:open(visual_mode)
end

function M.pull_request()
  local git_server = GitServerFactory.get_git_server()
  if git_server == nil then
    return
  end

  log.info "Opening current pull request..."

  git_server:open_pull_request()
end

function M.create_pull_request(target_branch)
  local git_server = GitServerFactory.get_git_server()
  if git_server == nil then
    return
  end

  local git_target_branch = config.target_branch
  if target_branch ~= nil and target_branch ~= "" then
    git_target_branch = target_branch
  end

  log.info "Creating pull request..."

  git_server:create_pull_request(git_target_branch)
end

return M
