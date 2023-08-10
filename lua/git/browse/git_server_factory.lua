local git = require "git.utils.git"
local log = require "git.utils.log"
local Github = require "git.browse.github_server"
local Gitlab = require "git.browse.gitlab_server"
local config = require("git.config")

local GitServerFactory = {}

local function _get_git_remote_url()
  local git_dir = git.get_git_repo()
  if git_dir == nil or git_dir == "" then
    return nil, nil, nil
  end

  local remote_url = git.run_git_cmd("git -C " .. git_dir .. ' remote get-url origin | tr -d "\n"')
  if remote_url == nil or remote_url == "" then
    return nil, nil, nil
  end

  local git_server, git_path = "", ""
  if remote_url:find "^git@" then
    git_server, git_path = remote_url:match "^git@([^:/]+):(.+)"
    git_server = "https://" .. git_server
  elseif remote_url:find "^ssh://git@" then
    git_server, _, git_path = remote_url:match "^ssh://git@([^:/]+)([:%d]*)/(.+)"
    git_server = "https://" .. git_server
  else
    git_server, git_path = remote_url:match "^(https?://[^/]+)/(.+)"
  end

  git_path = git_path:gsub("%.git$", "")

  return git_server, git_path, git_dir
end

function GitServerFactory.get_git_server()
  local base_url, git_path, git_dir = _get_git_remote_url()
  if base_url == nil or git_path == nil or git_dir == nil or base_url == "" or git_path == "" or git_dir == "" then
    log.error "Failed to get Git remote URL"

    return nil
  end

  local branch = git.get_current_branch_name()
  if branch == nil then
    log.error "Failed to get current branch"

    return nil
  end

  if base_url == nil or git_path == nil then
    return nil
  end

  if base_url:find "github" then
    return Github.new(base_url, git_path, git_dir, branch)
  end

  if base_url:find "gitlab" or config.is_private_gitlab(base_url) then
    return Gitlab.new(base_url, git_path, git_dir, branch)
  end

  log.error("Unsupported git server: " .. base_url)

  return nil
end

return GitServerFactory
