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

This uses a compiled neovim (from source) and submodules for all git plugins, ensuring perfect stability.
Everything: plugins, even neovim itself, will be upgraded by hand by me. The only exceptions are the quite standard
tools listed as prerequisites below, which are better off handled by your package manager.

## Prerequisites

You need to install `cmake` and `make` (they are surely available for your system, if not installed by default).

You also need [fzf](https://github.com/junegunn/fzf).

Below tools are optional and everything will work without it. But I suggest you get them. They are fairly standard
anyway, and you don't really have to think about them.
- [fd](https://github.com/sharkdp/fd) - better `find` utility
- [rg](https://github.com/BurntSushi/ripgrep) - better `grep` utility
- [bat](https://github.com/sharkdp/bat) - syntax highlighted previews when
  using fzf's native previewer
- [delta](https://github.com/dandavison/delta) - syntax highlighted git pager
  for git status, git log, git add -p, everything...

## Install

Clone this repository along with neovim and plugins
```bash
git clone --recursive -j8 https://github.com/porridgewithraisins/nvim ~/.config/nvim
cd ~/.config/nvim/neovim
```

Build neovim.
```bash
make -j$(nproc) CMAKE_BUILD_TYPE=Release
```

Now, install Neovim. Note that this won't touch your existing installation (if you have it) of neovim at `/usr/bin`.
Everything goes to `/usr/local/bin` and `/usr/local/share`.
```bash
sudo make install
```

## Plugins

TODO: add a listing here with short explanation

Nothing is lazy loaded. Everything just loads at the start. Of course, language servers are brought up and torn down
as and when required, but apart from that.

### Loading order

Below are dependencies `a --depends on--> b`. If you change the config, make sure you set them up in the correct order
i.e "manual lazy.nvim"

```
lsp_file_operations -> neo-tree
```

Yes, this does not scale. However, that is the plan!

## Usage, keybinds and commands

In progress.

UI wise:
 - Vim-native concepts such as the quickfix list.
 - Multicursor workflow using multiple-cursors.nvim.
 - Fuzzy workflow using fzf-lua.
 - Tree workflow using neo-tree.
 - A nice merge/PR review tool is inbuilt - diffview.nvim

Commands wise:
 - Very few keybinds to keep in mind - use longer commands for rarely used things.

Editing wise:
 - Tree-sitter integrated very well everywhere.

LSP:
 - Uses the inbuilt LSP (and inbuilt completion?).

What is not there:
 - Snippets (but nothing stopping you from just adding nvim-cmp and getting the whole kitchen sink)
