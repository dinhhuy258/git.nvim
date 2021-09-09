local config = require("git.config").config
local utils = require "git.utils"
local git = require "git.utils.git"

local M = {}

local GitType = {
  GITHUB = "github",
  GITLAB = "gitlab",
}

local function open_url(url)
  if vim.fn.has "win16" == 1 or vim.fn.has "win32" == 1 or vim.fn.has "win64" == 1 then
    vim.fn.system("start cmd /cstart /b " .. url)
  elseif vim.fn.has "mac" == 1 or vim.fn.has "macunix" == 1 or vim.fn.has "gui_macvim" == 1 then
    vim.fn.system('open "' .. url .. '"')
  else
    vim.fn.system('xdg-open "' .. url .. '" &> /dev/null &')
  end
end

local function get_git_remote_url()
  local git_root = git.get_git_repo()
  local git_remote_url = git.run_git_cmd("git -C " .. git_root .. ' remote get-url origin | tr -d "\n"')
  if git_remote_url == nil then
    return
  end

  if utils.starts_with(git_remote_url, "git@") then
    git_remote_url = git_remote_url:sub(#"git@" + 1)
    git_remote_url = "https://" .. git_remote_url
  end

  if utils.starts_with(git_remote_url, "git://") then
    git_remote_url = git_remote_url:sub(#"git://" + 1)
    git_remote_url = "https://" .. git_remote_url
  end

  git_remote_url = git_remote_url:gsub("com:", "com/")

  if utils.end_with(git_remote_url, ".git") then
    git_remote_url = git_remote_url:sub(1, -(#".git" + 1))
  end

  return git_remote_url
end

local function get_gitlab_merge_request_url(git_remote_url, commit_hash)
  local merge_request = git.run_git_cmd(
    'git ls-remote origin "*/merge-requests/*/head" | grep ' .. commit_hash .. ' | tr -d "\n"'
  )
  if merge_request == nil or merge_request == "" then
    utils.log("Failed to get merge request from commit hash " .. commit_hash)
    return
  end

  local merge_request_id = utils.split(merge_request, "/")[3]

  return git_remote_url .. "/merge_requests/" .. merge_request_id
end

local function get_github_pull_request_url(git_remote_url, commit_hash)
  local pull_request = git.run_git_cmd(
    'git ls-remote origin "refs/pull/*/head" | grep ' .. commit_hash .. ' | tr -d "\n"'
  )
  if pull_request == nil or pull_request == "" then
    utils.log("Failed to get pull request from commit hash " .. commit_hash)
    return
  end

  local pull_request_id = utils.split(pull_request, "/")[3]

  return git_remote_url .. "/pull/" .. pull_request_id
end

local function get_current_branch_name()
  return git.get_current_branch_name()
end

local function get_lastest_commit_hash(branch_name)
  return git.run_git_cmd("git rev-parse " .. "origin/" .. branch_name .. ' | tr -d "\n"')
end

local function get_git_site_type(git_remote_url)
  for _, git_site in pairs(GitType) do
    if vim.fn.stridx(git_remote_url, git_site) ~= -1 then
      return git_site
    end
  end

  return nil
end

local function get_git_repo_info()
  local git_remote_url = get_git_remote_url()
  if git_remote_url == nil or git_remote_url == "" then
    utils.log "Failed to get git remote url"
    return nil, nil, nil
  end

  local git_site_type = get_git_site_type(git_remote_url)
  if git_site_type == nil or git_site_type == "" then
    utils.log "Git site is not supported"
    return nil, nil, nil
  end

  local branch_name = get_current_branch_name()
  if branch_name == nil or branch_name == "" then
    utils.log "Failed to get current branch name"
    return nil, nil, nil
  end

  return git_remote_url, git_site_type, branch_name
end

function M.open(visual_mode)
  local git_remote_url, git_site_type, branch_name = get_git_repo_info()
  if git_remote_url == nil or git_site_type == nil or branch_name == nil then
    return
  end

  utils.log "Opening git..."

  if vim.fn.expand "%:h" ~= "" then
    -- Git file
    local git_root = git.get_git_repo()
    local absolute_path = vim.fn.expand "%:p"
    local relative_path = vim.fn.fnamemodify(vim.fn.expand "%", ":~:.")
    if utils.starts_with(absolute_path, git_root) then
      relative_path = absolute_path:sub(#git_root + 1)
    end

    local git_url = git_remote_url .. "/blob/" .. branch_name .. "/" .. relative_path

    if visual_mode then
      local first_line = vim.fn.getpos("'<")[2]
      local last_line = vim.fn.getpos("'>")[2]
      git_url = git_url .. "#L" .. first_line

      if git_site_type == GitType.GITHUB then
        open_url(git_url .. "-L" .. last_line)
        return
      end

      -- Gitlab
      open_url(git_url .. "-" .. last_line)
    else
      local linenr = tostring(vim.fn.line ".")
      open_url(git_url .. "#L" .. linenr)
    end
  else
    open_url(git_remote_url .. "/tree/" .. branch_name .. "/")
  end
end

function M.pull_request()
  local git_remote_url, git_site_type, branch_name = get_git_repo_info()
  if git_remote_url == nil or git_site_type == nil or branch_name == nil then
    return
  end

  utils.log "Opening a pull request..."

  local latest_commit_hash = get_lastest_commit_hash(branch_name)
  if latest_commit_hash == nil then
    utils.log("Failed to get the lastest commit from branch: " .. branch_name)
    return
  end

  local url = nil
  if git_site_type == GitType.GITHUB then
    url = get_github_pull_request_url(git_remote_url, latest_commit_hash)
  else
    -- Gitlab
    url = get_gitlab_merge_request_url(git_remote_url, latest_commit_hash)
  end

  if url ~= nil then
    open_url(url)
  end
end

function M.create_pull_request(target_branch)
  local git_remote_url, git_site_type, branch_name = get_git_repo_info()
  if git_remote_url == nil or git_site_type == nil or branch_name == nil then
    return
  end

  utils.log "Creating a pull request..."

  local git_target_branch = config.target_branch
  if target_branch ~= nil and target_branch ~= "" then
    git_target_branch = target_branch
  end

  local url = nil
  if git_site_type == GitType.GITHUB then
    url = git_remote_url .. "/compare/" .. git_target_branch .. "..." .. branch_name
  else
    -- Gitlab
    url = git_remote_url
      .. "/merge_requests/new?utf8=%E2%9C%93&merge_request[source_branch]="
      .. branch_name
      .. "&merge_request[target_branch]="
      .. git_target_branch
  end

  open_url(url)
end

return M
