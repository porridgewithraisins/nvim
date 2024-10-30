if argc() == 1 && isdirectory(argv(0)) | cd `=argv(0)` | endif
augroup General | au! | augroup END

set number relativenumber cursorline signcolumn=yes laststatus=3 lazyredraw splitbelow splitright virtualedit=block shiftround
set smartcase ignorecase infercase undofile nowrap nospell pumblend=10 cmdheight=0 showcmdloc=statusline spelloptions+=camel
set expandtab shiftwidth=4 softtabstop=4
let g:loaded_python3_provider = 0 | let g:loaded_ruby_provider = 0 | let g:loaded_netrwPlugin = 1 | let g:loaded_netrw = 1
au General BufReadPost *
            \ if index(['gitcommit', 'gitrebase', 'log'], &filetype) == -1 && line("'\"") > 0 && line("'\"") <= line("$") |
            \   exe "normal g'\"" |
            \ endif
au General FocusGained * checktime
au General VimResized * wincmd =
au General FileType gitcommit,gitrebase,markdown,text,tex,log setlocal wrap spell
au General TextYankPost * silent! lua vim.highlight.on_yank { higroup='IncSearch', timeout=300 }
au General BufNew * cd .
au General BufEnter,FocusGained,InsertLeave * if &buftype != 'quickfix' | set relativenumber | endif
au General BufLeave,FocusLost,InsertEnter   * if &buftype != 'quickfix' | set norelativenumber | endif
au General FileType gitcommit setlocal noundofile colorcolumn=+1 | silent 1 | startinsert
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
require('gitsigns').setup{}
require('nvim-autopairs').setup{}
EOF

xnoremap in :<C-u>call VisualNumber()<CR> | onoremap in :<C-u>normal vin<CR>
xnoremap ih :<C-u>Gitsigns select_hunk<CR> | onoremap ih :<C-u>Gitsigns select_hunk<CR>

function! IsGitWorkTree()
  let l:stdout = system("git rev-parse --git-dir 2> /dev/null")
  if l:stdout =~# '\.git'
    return 1
  endif
  return 0
endfunction

" keep default grepprg if not inside git dir, otherwise switch to git grep
if IsGitWorkTree()
    set grepprg=git\ grep\ -n\ $*
elseif executable('rg')
    set grepprg=rg\ --vimgrep "I don't want the uu thing.
else
    set grepprg=grep\ -HIn\ $*\ /dev/null
endif

function! Grep(...)
    return system(join([&grepprg] + [expandcmd(join(a:000, ' '))], ' '))
endfunction

command! -nargs=+ -complete=file_in_path -bar Grep cgetexpr Grep(<f-args>)

cnoreabbrev <expr> grep  (getcmdtype() ==# ':' && getcmdline() ==# 'grep')  ? 'Grep'  : 'grep'

nmap <leader>g :Grep <c-r><c-w><CR>

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

nnoremap <leader>e <Cmd>Neotree toggle<CR>
nnoremap <leader>ff <Cmd>FzfLua files<CR>
nnoremap <leader>b <Cmd>ls<CR>:b <Right>

lua << EOF
vim.api.nvim_create_user_command('Diagnostics', function(opts)
    vim.diagnostic.setqflist({
        open = true,
        severity = { min = tonumber(opts.args) or vim.diagnostic.severity.HINT }
    })
end, { nargs = '?' })
vim.keymap.set('n', 'L', vim.diagnostic.open_float)
EOF

nmap gd <C-]>
nnoremap gy <Cmd>lua vim.lsp.buf.type_definition()<CR>
noremap <c-f> <Cmd>lua vim.lsp.buf.format()<CR>
inoremap <c-f> <Cmd>lua vim.lsp.buf.format()<CR>
nnoremap ]c :if &diff <Bar> execute 'normal! ]c' <Bar> else <Bar> silent execute 'Gitsigns next_hunk' <Bar> endif<CR>
nnoremap [c :if &diff <Bar> execute 'normal! [c' <Bar> else <Bar> silent execute 'Gitsigns prev_hunk' <Bar> endif<CR>

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
require'fzf-lua'.setup {
    fzf_opts = { ['--history'] = vim.fn.stdpath("data") .. '/fzf-lua-history' },
}
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

nnoremap <leader>p <Cmd>call ToggleRegisterType()<cr>

noremap <M-j> 4j | noremap <M-k> 4k | noremap <M-l> 4l | noremap <M-h> 4h

set dictionary=/usr/share/dict/words thesaurus=~/.config/nvim/thesaurus.txt
inoremap <c-u> <c-g>u<c-u> | inoremap <c-w> <c-g>u<c-w>

" better window resizing, just do c-w >>>>>>>> keyboard smash! instead of c-w
" everytime. TODO - explore tinykeymap here
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

let g:linefly_options = {
    \ 'winbar': v:true,
    \ 'with_indent_status': v:true, 'with_macro_status': v:true, 'with_search_count': v:true,
    \ 'with_lsp_status': v:true, 'with_attached_clients': v:false, 'with_git_status': v:false,
\ }

tnoremap <expr> <C-r> '<C-\><C-N>"'.nr2char(getchar()).'pi'

" TODO consider https://github.com/tomtom/tinykeymap_vim
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
" TODO fallback to grep if rg doesn't exist, make the logic like --- if grepprg is currently rg, remove -uu option
" TODO make a HTML LSP that forwards to css lsp and js lsp, or even embeds
" them if needs be
" TODO use fzf_exec in some nice way and also complete=true in some nice way
