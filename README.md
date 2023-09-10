# git.nvim

git.nvim is the simple clone of the plugin [vim-fugitive](https://github.com/tpope/vim-fugitive) which is written in Lua.

## Install

[vim plug](https://github.com/junegunn/vim-plug)

```sh
Plug 'dinhhuy258/git.nvim'
```

[packer.nvim](https://github.com/wbthomason/packer.nvim)

```sh
use {
  'dinhhuy258/git.nvim'
}
```

## Requirements

- Neovim >= 0.5.0
- git

## Features

- Run git command in Neovim with `:Git`. Eg: `:Git status`
- Open git blame window, press enter on a line to view the commit where the line changed
- Open git browse, open pull request, create pull request in Github and Gitlab
- Git diff
- Git revert
- Works correctly with winbar enabled (or plugins making use of winbar, like barbecue.nvim)

For more information please refer this [file](https://github.com/dinhhuy258/git.nvim/blob/main/lua/git.lua)

## Usage

For the basic setup with default configurations

```lua
require('git').setup()
```

Configuration can be passed to the setup function. Here is an example with most of the default settings:

```lua
require('git').setup({
  default_mappings = true, -- NOTE: `quit_blame` and `blame_commit` are still merged to the keymaps even if `default_mappings = false`

  keymaps = {
    -- Open blame window
    blame = "<Leader>gb",
    -- Close blame window
    quit_blame = "q",
    -- Open blame commit
    blame_commit = "<CR>",
    -- Open file/folder in git repository
    browse = "<Leader>go",
    -- Open pull request of the current branch
    open_pull_request = "<Leader>gp",
    -- Create a pull request with the target branch is set in the `target_branch` option
    create_pull_request = "<Leader>gn",
    -- Opens a new diff that compares against the current index
    diff = "<Leader>gd",
    -- Close git diff
    diff_close = "<Leader>gD",
    -- Revert to the specific commit
    revert = "<Leader>gr",
    -- Revert the current file to the specific commit
    revert_file = "<Leader>gR",
  },
  -- Default target branch when create a pull request
  target_branch = "master",
  -- Private gitlab hosts, if you use a private gitlab, put your private gitlab host here
  private_gitlabs = { "https://xxx.git.com" },
  -- Enable winbar in all windows created by this plugin
  winbar = false,
})

```

## Command

`:Git` run git command in terminal

Eg: 
`:Git checkout -b test`

`:GitBlame` opens git blame window

`:GitDiff` opens a new diff that compares against the current index. You can also provide any valid git rev to the command. Eg: `:GitDiff HEAD~2`

`:GitDiffClose` close the git diff window

`:GitCreatePullRequest` create pull request in git repository, the default target branch is set in the `target_branch` option. If you provide the branch then the default `target_branch` will be ignored

Eg: 
`:GitCreatePullRequest`
`:GitCreatePullRequest test_branch`

`:GitRevert` revert to specific commit

`:GitRevertFile` revert the current file to specific commit

## Issues

- Some features may not work on window so pull request are welcome

## Credits

- [vim-fugitive](https://github.com/tpope/vim-fugitive)
