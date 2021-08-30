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

  vim.cmd [[command! -nargs=* GitCreatePullRequest lua require('git.browse').create_pull_request(<f-args>)]]
  vim.cmd [[command! -nargs=* GitDiff lua require("git.diff").open(<f-args>)]]
  vim.cmd [[command! GitDiffClose lua require("git.diff").close()]]
  vim.cmd [[command! -nargs=* Git lua require("git.cmd").cmd(<f-args>)]]
end

return M
