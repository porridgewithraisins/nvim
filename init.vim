if argc() == 1 && isdirectory(argv(0))
    cd `=argv(0)`
endif
augroup General
    au!
augroup END

" resets
set number relativenumber cursorline signcolumn=yes laststatus=3 lazyredraw splitbelow splitright virtualedit=block
set smartcase ignorecase undofile nowrap nospell
let g:loaded_python3_provider = 0
let g:loaded_ruby_provider = 0
let g:loaded_netrwPlugin = 1
let g:loaded_netrw = 1
au General BufReadPost *
  \ let excluded_filetypes = ['gitcommit', 'gitrebase', 'log'] |
  \ if index(excluded_filetypes, &filetype) == -1 |
  \   if line("'\"") > 1 && line("'\"") <= line('$') |
  \     silent! normal! g`" |
  \   endif |
  \ endif |
au General FocusGained * checktime
au General VimResized * wincmd =
au General FileType gitcommit,gitrebase,markdown,text,tex,log setlocal wrap spell textwidth=120
au General TextYankPost * silent! lua vim.highlight.on_yank { higroup='Visual', timeout=300 }
au General BufNew * cd .
set nofoldenable foldmethod=expr foldexpr=v:lua.vim.treesitter.foldexpr() foldtext=v:lua.vim.treesitter.foldtext()
lua << EOF
require("nvim-treesitter.configs").setup({
    auto_install = true,
    highlight = { enable = true },
    indent = { enable = true },
})
EOF

" space tabs muckery
set expandtab tabstop=4 shiftwidth=4 softtabstop=4
au General FileType make setlocal noexpandtab
command! -nargs=1 SetSpaces setlocal shiftwidth=<args> softtabstop=<args>

" colors
colorscheme catppuccin
au General VimEnter,Syntax *
            \ syntax keyword todo TODO FIXME NOTE XXX |
            \ highlight clear todo |
            \ highlight link todo DiagnosticUnderlineWarn

set wildignore+=**/node_modules/**,**/venv/**,**/__pycache__/**,**/dist/**,**/build/**,**/target/**

" leader key to space
let mapleader = " "
let maplocalleader = " "
silent! nnoremap <space> <nop>

let g:autosave_enabled = 0
let g:autosave_per_buffer = {}
au! General FocusLost,BufLeave,BufWinLeave,InsertLeave *
  \ if g:autosave_enabled || get(g:autosave_per_buffer, bufnr()) |
  \   if &filetype != '' && &buftype == '' |
  \     silent! write |
  \   endif |
  \ endif
command! ToggleAutoSave let g:autosave_enabled = !g:autosave_enabled
command! ToggleLocalAutoSave let g:autosave_per_buffer[bufnr()] = !get(g:autosave_per_buffer, bufnr())

" use files from vim
set runtimepath+=/usr/share/vim/vimfiles

"inbuilt plugins
packadd cfilter | packadd matchit | packadd nohlsearch | packadd justify

lua << EOF
require('gitsigns').setup{} require('nvim-autopairs').setup{}
EOF

nnoremap [q :cprev<cr> | nnoremap ]q :cnext<cr>

" 28 simple pseudo-text objects
" -----------------------------
" i_ i. i: i, i; i| i/ i\ i* i+ i- i# i$ i%
" a_ a. a: a, a; a| a/ a\ a* a+ a- a# a$ a%
" can take a count: 2i: 3a/
for char in [ '_', '.', ':', ',', ';', '<bar>', '/', '<bslash>', '*', '+', '-', '#', '$', '%']
    execute "xnoremap i" . char . " :<C-u>execute 'normal! ' . v:count1 . 'T" . char . "v' . (v:count1 + (v:count1 - 1)) . 't" . char . "'<CR>"
    execute "onoremap i" . char . " :normal vi" . char . "<CR>"
    execute "xnoremap a" . char . " :<C-u>execute 'normal! ' . v:count1 . 'F" . char . "v' . (v:count1 + (v:count1 - 1)) . 'f" . char . "'<CR>"
    execute "onoremap a" . char . " :normal va" . char . "<CR>"
endfor

" Number pseudo-text object (integer and float)
" ---------------------------------------------
" in
function! VisualNumber()
    call search('\d\([^0-9\.]\|$\)', 'cW')
    normal v
    call search('\(^\|[^0-9\.]\d\)', 'becW')
endfunction
xnoremap in :<C-u>call VisualNumber()<CR> | onoremap in :<C-u>normal vin<CR>
" Block comment pseudo-text objects
" ---------------------------------
" i? a?
xnoremap a? [*o]* | onoremap a? :<C-u>normal va?V<CR>
xnoremap i? [*jo]*k | onoremap i? :<C-u>normal vi?V<CR>
" C comment pseudo-text object
" ----------------------------
" i? a?
xnoremap i? [*jo]*k | onoremap i? :<C-u>normal vi?V<CR>
xnoremap a? [*o]* | onoremap a? :<C-u>normal va?V<CR>
" Last change pseudo-text objects
" -----------------------------------
" ik ak
xnoremap ik ` | onoremap ik :<C-u>normal vik<CR>
onoremap ak :<C-u>normal vikV<CR>
" XML/HTML/etc. attribute pseudo-text object
" ------------------------------------------
" ix ax
xnoremap ix a"oB | onoremap ix :<C-u>normal vix<CR>
xnoremap ax a"oBh | onoremap ax :<C-u>normal vax<CR>

function! IsGitWorkTree()
  let l:git=1
  let l:stdout = system("git rev-parse --git-dir 2> /dev/null")
  if l:stdout =~# '\.git'
    let l:git=0
  endif
  return l:git
endfunction

" keep default grepprg if not inside git dir, otherwise switch to git grep
if IsGitWorkTree() == 0
  set grepprg=git\ grep\ -n\ $*
else
  " TODO fallback to grep if rg doesn't exist
  " make the logic like --- if grepprg is currently rg, remove -uu option
  set grepprg=rg\ --vimgrep "I don't want the uu thing.
endif

function! Grep(...)
    return system(join([&grepprg] + [expandcmd(join(a:000, ' '))], ' '))
endfunction

command! -nargs=+ -complete=file_in_path -bar Grep cgetexpr Grep(<f-args>)

cnoreabbrev <expr> grep  (getcmdtype() ==# ':' && getcmdline() ==# 'grep')  ? 'Grep'  : 'grep'

augroup Quickfix
    au!
    au QuickFixCmdPost [^l]* cwindow | setlocal ma
    au WinEnter * if winnr('$') == 1 && &buftype == "quickfix"|q|endif
augroup END

silent !mkdir -p ~/.cache/nvim/sessions
function! GetSessionFile()
    let l:cwd = expand('%:p:h')
    let l:branch = substitute(system("git rev-parse --abbrev-ref HEAD 2>/dev/null"), '\n\+$', '', '')
    let l:encoded = substitute(l:cwd, '/', '_', 'g') . '__' . l:branch
    return '~/.cache/nvim/sessions/' . l:encoded . '.vim'
endfunction

function! ShouldRunSessionAutocmd()
    return argc() == 0 || (argc() == 1 && isdirectory(argv(0)))
endfunction

if $NVIM_USE_SESSIONS != ''
    command! ClearSession execute '!rm ' . GetSessionFile()
    augroup Sessions
        au
        au VimLeave * if ShouldRunSessionAutocmd() | execute 'mksession! ' . GetSessionFile() | endif
        au VimEnter * ++nested if ShouldRunSessionAutocmd() | silent! execute 'source ' . GetSessionFile() | endif
    augroup END
endif

nnoremap <leader>e :Neotree toggle<CR>
nnoremap <leader>ff :FzfLua files<CR>
nnoremap <leader>b :ls<CR>:b

lua << EOF
vim.api.nvim_create_user_command('Diagnostics', function(opts)
    vim.diagnostic.setqflist({
        open = true,
        severity = { min = tonumber(opts.args) or vim.diagnostic.severity.HINT }
    })
end, { nargs = '?' })
vim.keymap.set('n', 'L', vim.diagnostic.open_float)
EOF

lua << EOF
vim.keymap.set({ 'n', 'v', 'i' }, '<c-f>', vim.lsp.buf.format)
vim.keymap.set('n', 'gd', vim.lsp.buf.definition)
vim.keymap.set('n', 'gt', vim.lsp.buf.type_definition)
vim.keymap.set('n', ']c', function()
    if vim.wo.diff then
        vim.cmd.normal({ ']c', bang = true })
    else
        require 'gitsigns'.nav_hunk('next')
    end
end)
vim.keymap.set('n', '[c', function()
    if vim.wo.diff then
        vim.cmd.normal({ '[c', bang = true })
    else
        require 'gitsigns'.nav_hunk('prev')
    end
end)
EOF


lua << EOF
require("lsp-file-operations").setup {}
for _, lsp in ipairs({ "pylsp", "gopls", "ts_ls", "ccls", "bashls", "marksman", "texlab", "lua_ls" }) do
    require 'lspconfig'[lsp].setup {}
end
EOF

lua << EOF
require('bqf').setup { preview = { auto_preview = false } }
require("quicker").setup({
    keys = {
        {
            "R",
            function()
                require("quicker").refresh()
            end,
            desc = "Refresh quickfix list from source",
        },
    },
})
vim.keymap.set('n', '<leader>q', function()
    if vim.bo.buftype == "quickfix" then
        require 'quicker'.close()
    else
        require 'quicker'.open({ min_height = 10, focus = true })
    end
end)

EOF

lua << EOF
-- Flash search for any text
vim.keymap.set({ 'n', 'x', 'o' }, 's', function() require('flash').jump({ jump = { pos = "end" } }) end)
-- select labelled treesitter node(s)
vim.keymap.set({ 'n', 'x', 'o' }, 'S', function() require('flash').treesitter() end)
-- jump to labelled treesitter node
vim.keymap.set({ 'n', 'x', 'o' }, 'Q', function() require('flash').treesitter({ jump = { pos = "end" } }) end)
-- apply action in remote location e.g yr<flash search>iw and it restores cursor back here and you can paste iw can be
-- any text-object thing, and can also be a treesitter query, so like S and then you select a treesitter node.
vim.keymap.set({ 'o' }, 'r', function() require('flash').remote() end)
-- toggle for using flash-like search in regular / search
vim.keymap.set({ 'c' }, '<c-s>', function() require('flash').toggle() end)
EOF

lua << EOF
require'fzf-lua'.setup{}
require('neo-tree').setup {
    window = { width = 30 },
    filesystem = {
        follow_current_file = { enabled = true, leave_dirs_open = true },
        use_libuv_file_watcher = true,
        hijack_netrw_behavior = "disabled",
    },
    sources = { "filesystem", "buffers", "git_status", "document_symbols" },
    source_selector = {
        statusline = true,
        sources = {
            { source = "filesystem" }, { source = "buffers" }, { source = "git_status" }, { source = "document_symbols" },
        },
    },
    auto_clean_after_session_restore = true,
}
EOF

if filereadable(".vimrc") | source .vimrc | endif
