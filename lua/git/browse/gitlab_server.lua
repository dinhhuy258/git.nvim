local path = require "git.utils.path"
local git = require "git.utils.git"
local log = require "git.utils.log"

local GitServer = require "git.browse.git_server"

local Gitlab = {}

function Gitlab.new(git_url, git_path, git_dir, branch)
  local self = setmetatable(GitServer.new(git_url, git_path, git_dir, branch), { __index = Gitlab })

  return self
end

function Gitlab:open(visual_mode)
  GitServer._open(self, visual_mode)
end

function Gitlab:_open_visual_mode(relative_path, start_line, end_line)
  GitServer._open_url(path.join {
    self.git_url,
    self.path,
    "blob",
    self.branch,
    relative_path .. "#L" .. tostring(start_line) .. "-L" .. tostring(end_line),
  })
end

function Gitlab:open_pull_request()
  local latest_commit_hash = GitServer._get_latest_commit(self)
  if latest_commit_hash == nil then
    return
  end

  local merge_request = git.run_git_cmd(
    "git -C "
      .. self.git_dir
      .. ' ls-remote origin "*/merge-requests/*/head" | grep '
      .. latest_commit_hash
      .. ' | tr -d "\n"'
  )
  if merge_request == nil or merge_request == "" then
    log.error("Failed to get merge request from commit hash " .. latest_commit_hash)

    return
  end

  local merge_request_id = vim.split(merge_request, "/")[3]

  return GitServer._open_url(path.join { self.git_url, self.path, "merge_requests", merge_request_id })
end

function Gitlab:create_pull_request(target_branch)
  return GitServer._open_url(path.join {
    self.git_url,
    self.path,
    "/merge_requests/new?utf8=%E2%9C%93&merge_request[source_branch]="
      .. self.branch
      .. "&merge_request[target_branch]="
      .. target_branch,
  })
end

return Gitlab
