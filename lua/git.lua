local M = {}

function M.setup()
  vim.cmd [[command! -nargs=* Git lua require("git.cmd").cmd(<f-args>)]]

  local options = {
    noremap = true,
    silent = true,
    expr = false,
  }

  vim.api.nvim_set_keymap("n", "<Leader>gb", "<CMD>lua require('git.blame').blame()<CR>", options)
  vim.api.nvim_set_keymap("n", "<Leader>go", "<CMD>lua require('git.browse').open(false)<CR>", options)
  vim.api.nvim_set_keymap("x", "<Leader>go", ":<C-u> lua require('git.browse').open(true)<CR>", options)
  vim.api.nvim_set_keymap("n", "<Leader>gp", "<CMD>lua require('git.browse').pull_request()<CR>", options)
end

return M
