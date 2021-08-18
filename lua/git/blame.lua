local blame_state = require("git.state").blame_state

local M = {}

local function blameLinechars()
  local chars = vim.fn.strlen(vim.fn.getline ".")
  if vim.fn.exists "*synconcealed" and vim.wo.conceallevel > 1 then
    for col = 1, chars do
      chars = chars - vim.fn.synconcealed(vim.fn.line ".", col)[0]
    end
  end

  return chars
end

local function create_blame_win()
  vim.api.nvim_command "topleft vnew"
  local win = vim.api.nvim_get_current_win()
  local buf = vim.api.nvim_get_current_buf()

  vim.api.nvim_buf_set_option(buf, "buftype", "nofile")
  vim.api.nvim_buf_set_option(buf, "swapfile", false)
  vim.api.nvim_buf_set_option(buf, "bufhidden", "wipe")
  vim.api.nvim_buf_set_option(buf, "filetype", "git.nvim")
  vim.api.nvim_buf_set_option(buf, "buflisted", false)

  vim.api.nvim_win_set_option(win, "wrap", false)
  vim.api.nvim_win_set_option(win, "number", false)
  vim.api.nvim_win_set_option(win, "foldcolumn", "0")
  vim.api.nvim_win_set_option(win, "foldenable", false)
  vim.api.nvim_win_set_option(win, "foldenable", false)
  vim.api.nvim_win_set_option(win, "winfixwidth", true)
  vim.api.nvim_win_set_option(win, "signcolumn", "no")

  return win, buf
end

local function blame_syntax()
  local seen = {}
  local hash_colors = {}
  for lnum = 1, vim.fn.line "$" do
    local orig_hash = vim.fn.matchstr(vim.fn.getline(lnum), [[^\^\=[*?]*\zs\x\{6\}]])
    local hash = orig_hash
    hash = vim.fn.substitute(hash, [[\(\x\)\x]], [[\=submatch(1).printf("%x", 15-str2nr(submatch(1),16))]], "g")
    hash = vim.fn.substitute(hash, [[\(\x\x\)]], [[\=printf("%02x", str2nr(submatch(1),16)*3/4+32)]], "g")
    if hash ~= "" and orig_hash ~= "000000" and seen[hash] == nil then
      seen[hash] = 1
      if vim.wo.t_Co == "256" then
        local colors = vim.fn.map(vim.fn.matchlist(orig_hash, [[\(\x\)\x\(\x\)\x\(\x\)\x]]), "str2nr(v:val,16)")
        local r = colors[2]
        local g = colors[3]
        local b = colors[4]
        local color = 16 + (r + 1) / 3 * 36 + (g + 1) / 3 * 6 + (b + 1) / 3
        if color == 16 then
          color = 235
        elseif color == 231 then
          color = 255
        end
        hash_colors[hash] = " ctermfg=" .. tostring(color)
      else
        hash_colors[hash] = ""
      end
      local pattern = vim.fn.substitute(orig_hash, [[^\(\x\)\x\(\x\)\x\(\x\)\x$]], [[\1\\x\2\\x\3\\x]], "") .. [[*\>]]
      vim.cmd [[syn match FugitiveblameUncommitted "\%(^\^\=[?*]*\)\@<=\<0\{7,\}\>" skipwhite]]
      vim.cmd("syn match FugitiveblameHash" .. hash .. [[       "\%(^\^\=[*?]*\)\@<=]] .. pattern .. [[" skipwhite]])
    end

    for hash_value, cterm in pairs(hash_colors) do
      if cterm ~= nil or vim.fn.has "gui_running" or vim.fn.hash "termguicolors" and vim.wo.termguicolors then
        vim.cmd("hi FugitiveblameHash" .. hash_value .. " guifg=#" .. hash_value .. cterm)
      else
        vim.cmd("hi link FugitiveblameHash" .. hash_value .. " Identifier")
      end
    end
  end
end

local function on_blame_done(lines)
  local starting_win = vim.api.nvim_get_current_win()
  local current_pos = vim.api.nvim_win_get_cursor(starting_win)
  -- Save the state
  blame_state.file = vim.fn.expand "%:p"
  blame_state.starting_win = starting_win

  local blame_win, blame_buf = create_blame_win()

  vim.api.nvim_buf_set_lines(blame_buf, 0, -1, true, lines)
  vim.api.nvim_buf_set_option(blame_buf, "modifiable", false)
  vim.api.nvim_win_set_width(blame_win, blameLinechars() + 1)
  vim.api.nvim_win_set_cursor(blame_win, current_pos)
  -- We should call cursorbind, scrollbind here to avoid unexpected behavior
  vim.api.nvim_win_set_option(blame_win, "cursorbind", true)
  vim.api.nvim_win_set_option(blame_win, "scrollbind", true)

  vim.api.nvim_win_set_option(starting_win, "scrollbind", true)
  vim.api.nvim_win_set_option(starting_win, "cursorbind", true)

  -- Keymaps
  local options = {
    noremap = true,
    silent = true,
    expr = false,
  }

  vim.api.nvim_buf_set_keymap(0, "n", "q", "<CMD>q<CR>", options)
  vim.api.nvim_buf_set_keymap(0, "n", "<CR>", "<CMD>lua require('git.blame_commit').blame_commit()<CR>", options)
  vim.api.nvim_command "autocmd BufWinLeave <buffer> lua require('git.blame').blame_quit()"

  blame_syntax()
end

function M.blame_quit()
  vim.api.nvim_win_set_option(blame_state.starting_win, "scrollbind", false)
  vim.api.nvim_win_set_option(blame_state.starting_win, "cursorbind", false)
end

function M.blame()
  local fpath = vim.fn.expand "%:p"
  if fpath == "" or fpath == nil then
    return
  end

  local blame_cmd = "git --literal-pathspecs --no-pager -c blame.coloring=none -c blame.blankBoundary=false blame --show-number -- "
    .. fpath

  local lines = {}

  local function on_event(_, data, event)
    if event == "stdout" or event == "stderr" then
      if data then
        for i = 1, #data do
          if data[i] ~= "" then
            local commit = vim.fn.matchstr(data[i], [[^\^\=[?*]*\zs\x\+]])
            local commit_info = data[i]:match "%((.-)%)"
            table.insert(lines, commit .. " " .. commit_info)
          end
        end
      end
    end

    if event == "exit" then
      on_blame_done(lines)
    end
  end

  vim.fn.jobstart(blame_cmd, {
    on_stderr = on_event,
    on_stdout = on_event,
    on_exit = on_event,
    stdout_buffered = true,
    stderr_buffered = true,
  })
end

return M
