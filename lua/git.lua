local M = {}

function M.setup(cfg)
  require("git.config").setup(cfg)
  cfg = require("git.config").config

  local options = {
    noremap = true,
    silent = true,
    expr = false,
  }
  vim.api.nvim_set_keymap("n", cfg.keymaps.blame, "<CMD>lua require('git.blame').blame()<CR>", options)
  vim.api.nvim_set_keymap("n", cfg.keymaps.browse, "<CMD>lua require('git.browse').open(false)<CR>", options)
  vim.api.nvim_set_keymap("x", cfg.keymaps.browse, ":<C-u> lua require('git.browse').open(true)<CR>", options)
  vim.api.nvim_set_keymap(
    "n",
    cfg.keymaps.open_pull_request,
    "<CMD>lua require('git.browse').pull_request()<CR>",
    options
  )
  vim.api.nvim_set_keymap(
    "n",
    cfg.keymaps.create_pull_request,
    "<CMD>lua require('git.browse').create_pull_request()<CR>",
    options
  )
  vim.api.nvim_set_keymap("n", cfg.keymaps.diff, "<CMD>lua require('git.diff').open()<CR>", options)
  vim.api.nvim_set_keymap("n", cfg.keymaps.diff_close, "<CMD>lua require('git.diff').close()<CR>", options)
  vim.api.nvim_set_keymap("n", cfg.keymaps.revert, "<CMD>lua require('git.revert').open(false)<CR>", options)
  vim.api.nvim_set_keymap("n", cfg.keymaps.revert_file, "<CMD>lua require('git.revert').open(true)<CR>", options)

  vim.api.nvim_create_user_command(
    'GitCreatePullRequest',
    'lua require("git.browse").create_pull_request(<f-args>)',
    {
      bang = true,
      nargs = '*',
    })

  vim.api.nvim_create_user_command(
    'GitDiff',
    'lua require("git.diff").open(<f-args>)',
    {
      bang = true,
      nargs = '*',
    })

  vim.api.nvim_create_user_command(
    'GitDiffClose',
    'lua require("git.diff").close()',
    {
      bang = true,
    })

  vim.api.nvim_create_user_command(
    'Git',
    'lua require("git.cmd").cmd(<f-args>)',
    {
      bang = true,
      nargs = '*',
    })

  vim.api.nvim_create_user_command(
    'GitRevert',
    'lua require("git.revert").open(false)',
    {
      bang = true,
    })

  vim.api.nvim_create_user_command(
    'GitRevertFile',
    'lua require("git.revert").open(true)',
    {
      bang = true,
    })
end

return M
