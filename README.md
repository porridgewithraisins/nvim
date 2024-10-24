# nvim config

In progress.

 - figure out what to set key-binds for and what to leave as commands
 - figure out call hierarchy in neo-tree somehow
 - add more textobjects (treesitter based, my own delimiters, etc)
 - vimtex, emmet in opt: figure out the emmet remove tag bug
 - document symbols bug in neotree
 - lsp completion + signature help keybinds, autocmds
 - setup fzf-lua profile
 - multiple-cursors setup

 - Clean up plugins / sort them

## Versions

This uses a compiled neovim (from source) and submodules for all git plugins, ensuring perfect stability. Everything:
plugins, even neovim itself, will be upgraded by hand by me. The only exceptions are the quite standard tools listed as
prerequisites below, which are better off handled by your package manager.

## Prerequisites

You need to install `cmake` and `make` (they are surely available for your system, if not installed by default).

Neovim's only dynamically linked dependencies are libuv and glibc. libuv is a dependency of cmake and is thus already
covered. glibc is obviously covered.

These standalone CLI utilities enhance the experience and you probably will do well having them anyway, they are quite
useful.
- [fzf](https://github.com/junegunn/fzf) is required if you want to use fuzzy finding anywhere (in FzfLua, or in the
quickfix list).
- [fd](https://github.com/sharkdp/fd) - better `find` utility, will be used if it exists, otherwise falls back to `find`
- [rg](https://github.com/BurntSushi/ripgrep) - easier `grep` utility, will be used if it exists, otherwise falls back
to `grep`.
- [bat](https://github.com/sharkdp/bat) - useful tool outside vim, and here it gives syntax highlighted previews when
using fzf's native previewer, not really required, but I suggest getting it anyway.
- [delta](https://github.com/dandavison/delta) - useful tool outside vim, syntax highlighted git pager for git status,
git log, git add -p, everything... Inside vim, it gives the same when browsing git history in FzfLua, can forgo it, but
I suggest getting it anyway.

## Install

TODO: project makefile that does everything
TODO: dont forget about the git extension

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

Debugger:
 - Has nvim-dap, no GUI though, not a fan of dap-ui yet and also don't think stuffing a GUI debugger into vim is the
 greatest idea, for now.
