if argc() == 1 && isdirectory(argv(0)) | cd `=argv(0)` | endif
lua vim.loader.enable()
augroup General | au! | augroup END

set number relativenumber cursorline signcolumn=yes laststatus=3 lazyredraw splitbelow splitright virtualedit=block shiftround
set smartcase ignorecase infercase undofile nowrap nospell pumblend=10 cmdheight=0 showcmdloc=statusline spelloptions+=camel
set expandtab shiftwidth=4 softtabstop=4 inccommand=split
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
au General BufEnter,FocusGained * if &buftype != 'quickfix' | set relativenumber | endif
au General BufLeave,FocusLost * if &buftype != 'quickfix' | set norelativenumber | endif
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
            \ syntax keyword Todo TODO FIXME NOTE XXX |
            \ highlight clear Todo | highlight link Todo DiagnosticUnderlineWarn

command! TabHighlight syntax match Tab /\t/ | highlight link Tab Underlined

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
    set grepprg=git\ grep\ -n
elseif executable('rg')
    set grepprg=rg\ --vimgrep "I don't want the uu thing.
else
    set grepprg=grep\ -HIn
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

function! GetSessionFile()
    let l:branch = substitute(system("git rev-parse --abbrev-ref HEAD 2>/dev/null"), '\n\+$', '', '')
    if l:branch != ''
        return "./.git/session" . ":" . l:branch . ".vim"
    else
        silent !mkdir -p ~/.cache/nvim/sessions
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

nnoremap L <Cmd>lua vim.diagnostic.open_float()<CR>

nmap gd <c-]>
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
local kinds = {
    { jump = { pos = "end", offset = 1 } },
    { jump = { pos = "start" } },
    { jump = { pos = "range" } },
}
local kind_index = 0
vim.keymap.set({ 'n', 'x', 'o' }, 's', function() require('flash').jump(kinds[kind_index + 1]) end)
vim.keymap.set({ 'n', 'x', 'o' }, 'S', function() require('flash').treesitter(kinds[kind_index + 1]) end)
vim.keymap.set({ 'o' }, 'r', function() require('flash').remote(kinds[kind_index + 1]) end)
vim.keymap.set({'n', 'x', 'o'}, '<C-s>', function()
    kind_index = (kind_index + 1) % #kinds
    vim.opt.cmdheight, vim.opt.showcmdloc = 1, "last"
    vim.notify('Flash mode: ' .. kinds[kind_index + 1].jump.pos)
    vim.defer_fn(function() vim.opt.cmdheight, vim.opt.showcmdloc  = 0, "statusline" end, 1000)
end)
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
for _, lsp in ipairs({ "pyright", "gopls", "ts_ls", "ccls", "bashls", "marksman", "texlab", "lua_ls" }) do
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

lua <<EOF
if not vim.g.loaded_scrollview_gitsigns then
    vim.g.loaded_scrollview_gitsigns = true
    require('scrollview.contrib.gitsigns').setup()
end
EOF

lua require'completion' require'signature_help'

lua require('goto-preview').setup { default_mappings = true }

command! -nargs=+ WithIsk call WithIsk(<f-args>)
function! WithIsk(add_chars, remove_chars, cmd)
    let l:orig_isk = &isk
    exe 'setl isk+=' . a:add_chars . ' isk-=' . a:remove_chars . ' | ' . a:cmd
    let &isk = l:orig_isk
endfunction

inoremap <C-del> <C-o>de | inoremap <C-bs> <C-w>

" TODO consider https://github.com/tomtom/tinykeymap_vim
" TODO set fzf-lua up as required - see how to do something in the middle of the default and the max-perf
" TODO fix document symbols thing: https://github.com/nvim-neo-tree/neo-tree.nvim/issues/1584
" TODO add call hierarchy to neotree as well: https://github.com/nvim-neo-tree/neo-tree.nvim/issues/1277
" TODO undotree in neo-tree
" TODO nvim-treesitter-textobjects
" TODO figure out the stupid tag thing...
" TODO just need a thing to move around treesitter nodes if textobjects isn't enough for a generic thing
" TODO yank history in FZF?
" TODO multiple cursors
" TODO make a HTML LSP that forwards to css lsp and js lsp, or even embeds them if needs be
" TODO use fzf_exec in some nice way and also complete=true in some nice way
" TODO cleanup plugins and arrange init.vim nicely
" TODO incremental LSP rename / g/ / norm. ideas, also show in upto x buffers in multiple preview windows?
