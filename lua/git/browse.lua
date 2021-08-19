local utils = require "git.utils"

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

local function is_git_file()
  return vim.fn.expand "%:h" ~= ""
end

local function get_git_remote_url()
  local git_remote_url = utils.run_git_cmd 'git remote get-url origin | tr -d "\n"'
  if git_remote_url == nil then
    return
  end

  return vim.fn.system(
    "echo "
      .. git_remote_url
      .. [[ | sed -Ee 's#(git@|git://)#https://#' -e 's@com:@com/@' -e 's%\.git$%%' | tr -d "\n"]]
  )
end

local function get_gitlab_merge_request_url(git_remote_url, commit_hash)
  local merge_request = utils.run_git_cmd(
    'git ls-remote origin "*/merge-requests/*/head" | grep ' .. commit_hash .. ' | tr -d "\n"'
  )
  if merge_request == nil or merge_request == "" then
    utils.log("Failed to get merge request from commit hash " .. commit_hash)
    return
  end

  -- TODO: Handle in lua
  local merge_request_id = vim.fn.system("echo " .. merge_request .. [[ | awk -F'/' '{print $3}' | tr -d "\n"]])

  return git_remote_url .. "/merge_requests/" .. merge_request_id
end

local function get_github_pull_request_url(git_remote_url, commit_hash)
  local pull_request = utils.run_git_cmd(
    'git ls-remote origin "refs/pull/*/head" | grep ' .. commit_hash .. ' | tr -d "\n"'
  )
  if pull_request == nil or pull_request == "" then
    utils.log("Failed to get pull request from commit hash " .. commit_hash)
    return
  end

  -- TODO: Handle in lua
  local pull_request_id = vim.fn.system("echo " .. pull_request .. [[ | awk -F'/' '{print $3}' | tr -d "\n"]])

  return git_remote_url .. "/pull/" .. pull_request_id
end

local function get_current_branch_name()
  return utils.run_git_cmd 'git rev-parse --abbrev-ref HEAD | tr -d "\n"'
end

local function get_lastest_commit_hash(branch_name)
  return utils.run_git_cmd("git rev-parse " .. "origin/" .. branch_name .. ' | tr -d "\n"')
end

local function get_git_site_type(git_remote_url)
  for _, git_site in pairs(GitType) do
    if vim.fn.stridx(git_remote_url, git_site) ~= -1 then
      return git_site
    end
  end

  return nil
end

function M.open(visual_mode)
  local git_remote_url = get_git_remote_url()
  if git_remote_url == nil then
    utils.log "Failed to get git remote url"
    return
  end

  local branch_name = get_current_branch_name()
  if branch_name == nil then
    utils.log "Failed to get branch name"
    return
  end

  local git_site_type = get_git_site_type(git_remote_url)
  if git_site_type == nil then
    utils.log "Git site is not supported"
    return
  end

  if is_git_file() then
    local relative_path = vim.fn.expand "%"
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
  local git_remote_url = get_git_remote_url()
  if git_remote_url == nil then
    utils.log "Failed to get git remote url"
    return
  end

  local branch_name = get_current_branch_name()
  if branch_name == nil then
    utils.log "Failed to get branch name"
    return
  end

  local git_site_type = get_git_site_type(git_remote_url)
  if git_site_type == nil then
    utils.log "Git site is not supported"
    return
  end

  utils.log "Opening pull request..."

  local latest_commit_hash = get_lastest_commit_hash(branch_name)
  if latest_commit_hash == nil then
    utils.log("Failed to get the lastest commit from branch: " .. branch_name)
    return
  end

  local url = nil
  if git_site_type == GitType.GITHUB then
    url = get_github_pull_request_url(git_remote_url, latest_commit_hash)
  else
    url = get_gitlab_merge_request_url(git_remote_url, latest_commit_hash)
  end

  if url ~= nil then
    open_url(url)
  end
end

return M
