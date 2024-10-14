# nvim config

In progress.

 - figure out what to set key-binds for and what to leave as commands
 - figure out call hierarchy in neo-tree somehow
 - do sessions stuff :mksession vechu
 - add more textobjects (treesitter based, my own delimiters, etc)
 - vimtex
 - add `[]` navigation to the treesitter based textobjects
 - document symbols bug in neotree
 - lsp completion + signature help keybinds, autocmds
 - setup fzf-lua profile
 - emmet
 - nvim-surround?
 - multiple-cursors keybinds

## Versions

This uses a compiled neovim (from source), and submodules for all git plugins, ensuring perfect stability.
Everything, including neovim, will be upgraded by hand.

## Plugins

TODO: add a listing here with short explanation

### Loading order

Below are dependencies `a --depends on--> b`. Make sure you set them up in the correct order i.e "manual lazy"

```
lsp_file_operations -> neo-tree
```

## Usage, keybinds and commands

In progress.

UI wise:
 - Heavy reliance on vim-native concepts such as the quickfix list.
 - Auxiliary multicursor workflow using multiple-cursors.nvim.
 - Auxiliary fuzzy workflow using fzf-lua.
 - Auxiliary tree workflow using neo-tree.

Commands wise:
 - Very few keybinds to keep in mind - use longer commands for rarely used things.

Editing wise:
 - Tree-sitter integrated very well everywhere.

LSP:
 - Uses the inbuilt LSP (and inbuilt completion?).

What is not there:
 - Snippets (but nothing stopping you from just using nvim-cmp and getting the whole kitchen sink)
