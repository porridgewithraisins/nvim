if argc() == 1 && isdirectory(argv(0)) | cd `=argv(0)` | endif
augroup General | au! | augroup END

set number relativenumber cursorline signcolumn=yes laststatus=3 lazyredraw splitbelow splitright virtualedit=block shiftround
set smartcase ignorecase infercase undofile nowrap nospell pumblend=10 cmdheight=0 showcmdloc=statusline spelloptions+=camel
let g:loaded_python3_provider = 0 | let g:loaded_ruby_provider = 0 | let g:loaded_netrwPlugin = 1 | let g:loaded_netrw = 1
au General BufReadPost *
            \ if index(['gitcommit', 'gitrebase', 'log'], &filetype) == -1 && line("'\"") > 0 && line("'\"") <= line("$") |
            \   exe "normal g'\"" |
            \ endif
au General FocusGained * checktime
au General VimResized * wincmd =
au General FileType gitcommit,gitrebase,markdown,text,tex,log setlocal wrap spell textwidth=120
au General TextYankPost * silent! lua vim.highlight.on_yank { higroup='IncSearch', timeout=300 }
au General BufNew * cd .
au General BufEnter,FocusGained,InsertLeave * if &buftype != 'quickfix' | set relativenumber | endif
au General BufLeave,FocusLost,InsertEnter   * if &buftype != 'quickfix' | set norelativenumber | endif
au General FileType gitcommit setlocal textwidth=72 colorcolumn=73 noundofile
au General FileType gitcommit silent 1 | startinsert
au General TermOpen * startinsert

set nofoldenable foldmethod=expr foldexpr=v:lua.vim.treesitter.foldexpr() foldtext=v:lua.vim.treesitter.foldtext()
lua << EOF
require("nvim-treesitter.configs").setup({
    auto_install = true,
    highlight = { enable = true },
    indent = { enable = true },
})
EOF

command! -nargs=1 SetSpaces setlocal shiftwidth=<args> softtabstop=<args>

" colors
colorscheme catppuccin
au General VimEnter,Syntax *
            \ syntax keyword todo TODO FIXME NOTE XXX |
            \ highlight clear todo |
            \ highlight link todo DiagnosticUnderlineWarn

" show all the tabs in the file visually underlined
command TabHighlight syntax match Tab /\t/ | highlight link Tab Underlined

set wildignore+=**/node_modules/**,**/venv/**,**/__pycache__/**,**/dist/**,**/build/**,**/target/**

" leader key to space
let mapleader = " "
let maplocalleader = " "
silent! nnoremap <space> <nop>

:map ' `

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
  set grepprg=rg\ --vimgrep "I don't want the uu thing.
endif

function! Grep(...)
    return system(join([&grepprg] + [expandcmd(join(a:000, ' '))], ' '))
endfunction

command! -nargs=+ -complete=file_in_path -bar Grep cgetexpr Grep(<f-args>)

cnoreabbrev <expr> grep  (getcmdtype() ==# ':' && getcmdline() ==# 'grep')  ? 'Grep'  : 'grep'

nmap <leader>g :Grep <c-r><c-w><cr>

augroup Quickfix
    au!
    au QuickFixCmdPost [^l]* cwindow | setlocal ma
    au WinEnter * if winnr('$') == 1 && &buftype == "quickfix"|q|endif
augroup END

silent !mkdir -p ~/.cache/nvim/sessions
function! GetSessionFile()
    let l:branch = substitute(system("git rev-parse --abbrev-ref HEAD 2>/dev/null"), '\n\+$', '', '')
    if l:branch != ''
        return "./.git/session" . ":" . l:branch . ".vim"
    else
        return "~/.cache/nvim/sessions/" . substitute(expand('%:p:h'), '/', '_', 'g') . '.vim'
    endif
endfunction

function! ShouldRunSessionAutocmd()
    return argc() == 0 || (argc() == 1 && isdirectory(argv(0)))
endfunction

if $NVIM_USE_SESSIONS != '' " TODO did this while developing, make this proper with runtime check later
    command! ClearSession execute '!rm ' . GetSessionFile()
    augroup Sessions
        au
        au BufEnter,VimLeave * if ShouldRunSessionAutocmd() | execute 'mksession! ' . GetSessionFile() | endif
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
vim.keymap.set('n', 'gy', vim.lsp.buf.type_definition)
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

lua << EOF
require("lsp-file-operations").setup {}
local capabilities = vim.lsp.protocol.make_client_capabilities() -- TODO: get rid of this once its part of neovim
capabilities.workspace.didChangeWatchedFiles.dynamicRegistration = true -- TODO: remove this once its the default
capabilities = vim.tbl_deep_extend('force', capabilities, require'lsp-file-operations'.default_capabilities())
for _, lsp in ipairs({ "pylsp", "gopls", "ts_ls", "ccls", "bashls", "marksman", "texlab", "lua_ls" }) do
    require 'lspconfig'[lsp].setup {capabilities}
end
EOF

if filereadable(".git/.vimrc") | source .git/.vimrc | endif | if filereadable(".git/.nvimrc") | source .git/.nvimrc | endif

function! ToggleRegisterType()
    let current_type = getregtype('"')
    if current_type ==# 'v'
        call setreg('"', trim(getreg('"'), " "), 'l')
    else
        call setreg('"', trim(getreg('"'), "\n"), 'c')
    endif
endfunction

nnoremap <leader>p :call ToggleRegisterType()<cr>

noremap <M-j> 4j | noremap <M-k> 4k | noremap <M-l> 4l | noremap <M-h> 4h

set dictionary=/usr/share/dict/words thesaurus=~/.config/nvim/thesaurus.txt
inoremap <c-u> <c-g>u<c-u> | inoremap <c-w> <c-g>u<c-w>

" better window resizing, just do c-w >>>>>>>> keyboard smash! instead of c-w
" everytime
nmap <C-W>+ <C-W>+<SID>ws | nmap <C-W>- <C-W>-<SID>ws
nmap <C-W>> <C-W>><SID>ws | nmap <C-W>< <C-W><<SID>ws
nnoremap <script> <SID>ws+ 10<C-W>+<SID>ws | nnoremap <script> <SID>ws- 10<C-W>-<SID>ws
nnoremap <script> <SID>ws> 10<C-W>><SID>ws | nnoremap <script> <SID>ws< 10<C-W><<SID>ws
nmap <SID>ws <Nop>

command! -bang QA if tabpagenr('$') > 1 | exec 'tabclose<bang>' | else | exec 'qa<bang>' | endif
command! -bang QAA exec 'qa<bang>'
cnoreabbrev <expr> qa 'QA'

command! -nargs=1 -complete=file WriteQF execute writefile([json_encode(getqflist({'all': 1}))], <f-args>)
command! -nargs=1 -complete=file ReadQF call setqflist([], ' ', json_decode(get(readfile(<f-args>), 0, '')))

set completeopt=menu,fuzzy,menuone,popup,noinsert,noselect

lua << EOF
vim.g.linefly_options = {
    winbar = true,
    with_indent_status = true, with_macro_status = true, with_search_count = true,
    with_lsp_status = true, with_attached_clients = false, with_git_status = false,
}
EOF

tnoremap <expr> <C-r> '<C-\><C-N>"'.nr2char(getchar()).'pi'

" TODO consider https://github.com/tomtom/tinykeymap_vim
" TODO consider camelCase textobjects etc
" TODO set fzf-lua up as required
" Need to figure out how to send selected items only to quickfix list
" TODO fix document symbols thing: https://github.com/nvim-neo-tree/neo-tree.nvim/issues/1584
" TODO add call hierarchy to neotree as well: https://github.com/nvim-neo-tree/neo-tree.nvim/issues/1277
" TODO nvim-treesitter-textobjects
" TODO yank history in FZF
" TODO undotree in neo-tree
" TODO completion -- nearly done
" TODO multiple cursors
" TODO flash/leap/hop/syntax-tree-surfer/whatever, choose the right combination
" TODO latex tables
" TODO fallback to grep if rg doesn't exist, make the logic like --- if grepprg is currently rg, remove -uu option
" TODO make a HTML LSP that forwards to css lsp and js lsp, or even embeds
" them if needs be
