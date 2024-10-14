-- make each files "knownn name" relative to current directory
vim.cmd[[au bufnew * cd .]]
-- number for current line, relative number for other lines
vim.opt.number = true vim.opt.relativenumber = true
-- highlight current line
vim.opt.cursorline = true
-- single status line for all open splits
vim.opt.laststatus = 3
-- column after line numbers to show stuff like git signs, folds etc
vim.opt.signcolumn = "yes"

-- space/tabs muckery
vim.opt.expandtab = true vim.opt.tabstop = 4 vim.opt.shiftwidth = 4
vim.opt.softtabstop = 4
-- Override for buffer
function SetSpaces(count)
    vim.local_opt.shiftwidth = count
    vim.local_opt.softtabstop = count
end
-- For makefiles, use tab bytes
vim.api.nvim_create_autocmd("FileType", {
    pattern = "make",
    callback = function()
        vim.local_opt.expandtab = false   -- Use actual tabs instead of spaces
    end
})

-- stop nvim from trying to find a python context to set up its scripting
-- we get faster startup with this (since I don't have the python scripting engine installed)
vim.g.loaded_python3_provider = 0

-- buffer input in command line
function SelectBufferNative()
    vim.cmd('ls')
    vim.api.nvim_input(':b ')
end

-- set leader key to space
vim.keymap.set({"n", "v"}, " ", "<Nop>", { silent = true, remap = false })
vim.g.mapleader = " "
vim.g.maplocalleader = " "

-- tree UI
-- disable inbuilt file manager
vim.g.loaded_netrwPlugin = 1
vim.g.loaded_netrw = 1

require('neo-tree').setup{
    window = { width = 30 },
    filesystem = {
        follow_current_file = { enabled = true, leave_dirs_open = true },
        use_libuv_file_watcher = true,
    },
    sources = { "filesystem", "buffers", "git_status", "document_symbols" },
    source_selector = {
        statusline = true,
            sources = {
              { source = "filesystem" },
              { source = "buffers" },
              { source = "git_status" },
              { source = "document_symbols" },
            },
    }
}

-- renaming file in neotree will update imports, and other similar functionality
require("lsp-file-operations").setup{}
-- show menu for autocomplete, menuone makes it so it shows the menu even if there's only one item
-- noinsert makes it so it won't autoinsert the highlighted match until you select it
-- popup shows the preview in a popup window
vim.opt.completeopt = "menu,menuone,noinsert,popup"
-- setup servers
for _, lsp in ipairs({ "pylsp", "gopls", "ts_ls", "ccls", "bashls", "marksman", "texlab", "lua_ls"}) do
    require'lspconfig'[lsp].setup{}
end

-- auto install grammar for any file you open
-- enable treesitter based syntax highlighting as well as indentation
require("nvim-treesitter.configs").setup({
    auto_install = true,
    highlight = { enable = true },
    indent = { enable = true },
})

-- reset folds when opening file
vim.opt.foldenable = false
-- when calling any fold function, use treesitter based folding
vim.opt.foldmethod = "expr"
vim.opt.foldexpr = "v:lua.vim.treesitter.foldexpr()"
vim.opt.foldtext = "v:lua.vim.treesitter.foldtext()"

-- Git signs
-- Useful git commands + highlighting git regions in gutter
require'gitsigns'.setup{}

vim.cmd.colorscheme "catppuccin"

-- multiple cursors
require('multiple-cursors').setup{}

-- highlight colors like #c13121 rgb(100 100 100) (any css syntax) with the actual color
require('nvim-highlight-colors').setup{}

-- fuzzy find over anything
require("fzf-lua").setup{
-- saw something about code actions here? see about that
}

-- custom autocmds, read the desc of each
local general = vim.api.nvim_create_augroup("General", { clear = true })
vim.api.nvim_create_autocmd("BufReadPost", {
    callback = function()
        local excluded_filetypes = { "gitcommit", "gitrebase", "log" }
        if not vim.tbl_contains(excluded_filetypes, vim.bo.filetype) then
            if vim.fn.line "'\"" > 1 and vim.fn.line "'\"" <= vim.fn.line "$" then
                vim.cmd 'normal! g`"'
            end
        end
    end,
    group = general,
    desc = "Go to the last cursor position (except for git and log files)",
})

vim.api.nvim_create_autocmd("TextYankPost", {
    callback = function()
        require("vim.highlight").on_yank { higroup = "Visual", timeout = 200 }
    end,
    group = general,
    desc = "Highlight when yanking",
})

vim.opt.autoread = true
vim.api.nvim_create_autocmd("FocusGained", {
    callback = function()
        vim.cmd "checktime"
    end,
    group = general,
    desc = "Update file when there are changes",
})

vim.api.nvim_create_autocmd("VimResized", {
    callback = function()
        vim.cmd "wincmd ="
    end,
    group = general,
    desc = "Equalize splits reactively when terminal is resized",
})

vim.opt_local.wrap = false
vim.opt_local.spell = false
vim.api.nvim_create_autocmd("FileType", {
    pattern = { "gitcommit", "gitrebase", "markdown", "text", "tex", "log" },
    callback = function()
        vim.opt_local.wrap = true
        vim.opt_local.textwidth=120
        vim.opt_local.spell = true
    end,
    group = general,
    desc = "Enable wrap and spell in these filetypes",
})

vim.g.autosave_enabled = false
vim.g.autosave_per_buffer = {}
function ToggleAutoSave()
    vim.g.autosave_enabled = not vim.g.autosave_enabled
end
function ToggleLocalAutoSave()
    vim.g.autosave_per_buffer[vim.fn.bufnr()] = not vim.g.autosave_per_buffer[vim.fn.bufnr()]
end
vim.api.nvim_create_autocmd({ "FocusLost", "BufLeave", "BufWinLeave", "InsertLeave" }, {
    callback = function()
        if vim.g.autosave_enabled or vim.g.autosave_per_buffer[vim.fn.bufnr()] then
            if vim.bo.filetype ~= "" and vim.bo.buftype == "" then
                vim.cmd "silent! w"
            end
        end
    end,
    group = general,
    desc = "Auto Save",
})

require("quicker").setup({
    keys = {
        {
            ">",
            function()
                require("quicker").expand({ before = 2, after = 2, add_to_existing = true })
            end,
            desc = "Expand quickfix context",
        },
        {
            "<",
            function()
                require("quicker").collapse()
            end,
            desc = "Collapse quickfix context",
        },
        {
            "R",
            function()
                require("quicker").refresh()
            end,
            desc = "Refresh the results from source",
        },
    },
})

require('nvim-surround').setup{}

-- Keymaps and Commands

-- system clipboard yank/puts
vim.keymap.set({'n', 'v'}, '<leader>yy', '"+yy', { noremap = true })
vim.keymap.set({'n', 'v'}, '<leader>y', '"+y', { noremap = true })
vim.keymap.set({'n', 'v'}, '<leader>p', '"+p', { noremap = true })
vim.keymap.set({'n', 'v'}, '<leader>P', '"+P', { noremap = true })

-- e.g :SetSpaces 2
vim.api.nvim_create_user_command('SetSpaces', function(opts)
    SetSpaces(tonumber(opts.args))
end, { nargs = 1 })

-- e.g :ToggleAutoSave
vim.api.nvim_create_user_command('ToggleAutoSave', ToggleAutoSave, {})

vim.keymap.set('n', 'K', vim.lsp.buf.hover)
vim.keymap.set({'n', 'v', 'i'}, '<c-f>', vim.lsp.buf.format)
vim.keymap.set('n', 'gd', vim.lsp.buf.definition)
vim.keymap.set('n', 'gt', vim.lsp.buf.type_definition)
vim.keymap.set('n', 'gs', vim.lsp.buf.signature_help)
vim.keymap.set('n', 'gr', function() vim.cmd('FzfLua lsp_references') end)

vim.keymap.set('n', ']c', function()
    if vim.wo.diff then
        vim.cmd.normal({']c', bang = true})
    else
        require'gitsigns'.nav_hunk('next')
    end
end)
vim.keymap.set('n', '[c', function()
    if vim.wo.diff then
        vim.cmd.normal({'[c', bang = true})
    else
        require'gitsigns'.nav_hunk('prev')
    end
end)

vim.keymap.set('n', '<leader>d', vim.diagnostic.open_float)
vim.keymap.set('n', '<leader>e', function() vim.cmd('Neotree toggle') end)
vim.keymap.set('n', '<leader>ff', function() vim.cmd('FzfLua files') end)
vim.keymap.set('n', '<leader>fb', function() vim.cmd('FzfLua buffers') end)
vim.keymap.set('n', '<leader>fg', function() vim.cmd('FzfLua live_grep') end)
vim.keymap.set('n', '<leader>lb', SelectBufferNative, { noremap = true, silent = true })
vim.keymap.set('n', '<leader>q', function() require'quicker'.toggle() end)
vim.keymap.set('n', '[q', ':cprev<cr>')
vim.keymap.set('n', ']q', ':cnext<cr>')


-- Flash search for any text
vim.keymap.set({'n', 'x', 'o'}, '<CR>', function() require('flash').jump({jump = { pos = "end" } }) end)
-- select labelled treesitter node(s)
vim.keymap.set({'n', 'x', 'o'}, '<S-CR>', function() require('flash').treesitter() end)
-- jump to labelled treesitter node
vim.keymap.set({'n', 'x', 'o'}, 'Q', function() require('flash').treesitter({ jump = { pos = "end" } }) end)
-- apply action in remote location e.g yr<flash search>iw and it restores cursor back here and you can paste iw can be
-- any text-object thing, and can also be a treesitter query, so like S and then you select a treesitter node.
vim.keymap.set({'o'}, 'r', function() require('flash').remote() end)
-- toggle for using flash-like search in regular / search
vim.keymap.set({ 'c' }, '<c-s>', function() require('flash').toggle() end)

-- TODO: set fzf-lua up as required
-- TODO fix document symbols thing: https://github.com/nvim-neo-tree/neo-tree.nvim/issues/1584
-- TODO add call hierarchy to neotree as well: https://github.com/nvim-neo-tree/neo-tree.nvim/issues/1277
-- TODO sessions :mksession thing
-- TODO Add custom textobjects, then add keybinds for treesitter-textobjects as appropriate, considering that flash already exists.
-- TODO emmet
-- TODO inbuilt completion
-- TODO: multiple cursors keybinds + mouse click thing
