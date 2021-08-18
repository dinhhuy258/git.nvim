local M = {}

function M.setup()
  local options = {
    noremap = true,
    silent = true,
    expr = false,
  }

  vim.api.nvim_set_keymap("n", "<Leader>gb", "<CMD>lua require('git.blame').blame()<CR>", options)
end

return M
