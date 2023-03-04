local path = require "git.utils.path"
local git = require "git.utils.git"
local log = require "git.utils.log"

local GitServer = require "git.browse.git_server"

local Github = {}

function Github.new(git_url, git_path, git_dir, branch)
  local self = setmetatable(GitServer.new(git_url, git_path, git_dir, branch), { __index = Github })

  return self
end

function Github:open(visual_mode)
  GitServer._open(self, visual_mode)
end

function Github:open_pull_request()
  local latest_commit_hash = GitServer._get_latest_commit(self)
  if latest_commit_hash == nil then
    return
  end

  local pull_request = git.run_git_cmd(
    "git -C " .. self.git_dir .. ' ls-remote origin "refs/pull/*/head" | grep ' .. latest_commit_hash .. ' | tr -d "\n"'
  )

  if pull_request == nil or pull_request == "" then
    log.error("Failed to get pull request from commit hash " .. latest_commit_hash)
    return
  end

  local pull_request_id = vim.split(pull_request, "/")[3]

  return GitServer._open_url(path.join { self.git_url, self.path, "pull", pull_request_id })
end

function Github:_open_visual_mode(relative_path, start_line, end_line)
  GitServer._open_url(path.join {
    self.git_url,
    self.path,
    "blob",
    self.branch,
    relative_path .. "#LL" .. tostring(start_line) .. "-L" .. tostring(end_line),
  })
end

function Github:create_pull_request(target_branch)
  return GitServer._open_url(path.join { self.git_url, self.path, "compare", target_branch .. "..." .. self.branch })
end

return Github
