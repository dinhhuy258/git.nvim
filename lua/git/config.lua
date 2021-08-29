local M = {}

M.config = {}

local default_cfg = {
  keymaps = {
    blame = "<Leader>gb",
    quit_blame = "q",
    blame_commit = "<CR>",
    browse = "<Leader>go",
    open_pull_request = "<Leader>gp",
    create_pull_request = "<Leader>gn",
    diff = "<Leader>gd",
  },
  target_branch = "master",
}

function M.setup(cfg)
  if cfg == nil then
    cfg = {}
  end

  for k, v in pairs(default_cfg) do
    if cfg[k] ~= nil then
      if type(v) == "table" then
        M.config[k] = vim.tbl_extend("force", v, cfg[k])
      else
        M.config[k] = cfg[k]
      end
    else
      M.config[k] = default_cfg[k]
    end
  end
end

return M
