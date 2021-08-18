local M = {}

function M.setup()
  vim.cmd [[command! -nargs=* Git lua require("git.cmd").cmd(<f-args>)]]

  local options = {
    noremap = true,
    silent = true,
    expr = false,
  }

  vim.api.nvim_set_keymap("n", "<Leader>gb", "<CMD>lua require('git.blame').blame()<CR>", options)
end

return M
