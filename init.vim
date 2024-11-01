if argc() == 1 && isdirectory(argv(0)) | cd `=argv(0)` | endif
lua vim.loader.enable()
augroup General | au! | augroup END

set number relativenumber cursorline signcolumn=yes laststatus=3 lazyredraw splitbelow splitright virtualedit=block shiftround
set smartcase ignorecase infercase undofile nowrap nospell pumblend=10 cmdheight=0 showcmdloc=statusline spelloptions+=camel
set expandtab shiftwidth=4 softtabstop=4 inccommand=split
let g:loaded_python3_provider = 0 | let g:loaded_ruby_provider = 0 | let g:loaded_node_provider = 0 | let g:loaded_perl_provider = 0
let g:loaded_netrwPlugin = 1 | let g:loaded_netrw = 1
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
            \ highlight clear Todo | highlight link Todo DiagnosticUnderlineWarn |
            \ highlight WinSeparator guifg=Bold

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
cnoreabbrev <expr> grep (getcmdtype() ==# ':' && getcmdline() ==# 'grep') ? 'Grep'  : 'grep'
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

nmap gd <Cmd>lua vim.lsp.buf.definition({ reuse_win = true })<CR>
nmap grr <Cmd>lua vim.lsp.buf.references({ reuse_win = true })<CR>
nmap gri <Cmd>lua vim.lsp.buf.implementation({ reuse_win = true })<CR>
nmap gy <Cmd>lua vim.lsp.buf.type_definition({ reuse_win = true })<CR>
noremap <c-f> <Cmd>lua vim.lsp.buf.format()<CR> | inoremap <c-f> <Cmd>lua vim.lsp.buf.format()<CR>
nnoremap ]c :if &diff <Bar> execute 'normal! ]c' <Bar> else <Bar> silent execute 'Gitsigns next_hunk' <Bar> endif<CR>
nnoremap [c :if &diff <Bar> execute 'normal! [c' <Bar> else <Bar> silent execute 'Gitsigns prev_hunk' <Bar> endif<CR>

lua << EOF
require('bqf').setup { preview = { auto_preview = false } }
require("quicker").setup({
    keys = {
        { "R", function() require("quicker").refresh() end },
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
    if not vim.g["idempotent_loaded_lsp_"..lsp] then
        require'lspconfig'[lsp].setup {capabilities}
        vim.g["idempotent_loaded_lsp_"..lsp] = true
    end
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

" TODO - explore tinykeymap here
nmap <C-W>+ <C-W>+<SID>ws | nmap <C-W>- <C-W>-<SID>ws
nmap <C-W>> <C-W>><SID>ws | nmap <C-W>< <C-W><<SID>ws
nnoremap <script> <SID>ws+ 10<C-W>+<SID>ws | nnoremap <script> <SID>ws- 10<C-W>-<SID>ws
nnoremap <script> <SID>ws> 10<C-W>><SID>ws | nnoremap <script> <SID>ws< 10<C-W><<SID>ws
nmap <SID>ws <Nop>

command! -bang QA if tabpagenr('$') > 1 | exec 'tabclose<bang>' | else | exec 'qa<bang>' | endif
command! -bang QAA exec 'qa<bang>'
cnoreabbrev qa QA
cnoreabbrev Q q

command! -nargs=1 -complete=file WriteQF execute writefile([json_encode(getqflist({'all': 1}))], <f-args>)
command! -nargs=1 -complete=file ReadQF call setqflist([], ' ', json_decode(get(readfile(<f-args>), 0, '')))

set completeopt=menu,fuzzy,popup,noinsert,noselect

let g:linefly_options = {
    \ 'winbar': v:true,
    \ 'with_indent_status': v:true, 'with_macro_status': v:true, 'with_search_count': v:true,
    \ 'with_lsp_status': v:true, 'with_attached_clients': v:false, 'with_git_status': v:false,
\ }

tnoremap <expr> <C-r> '<C-\><C-N>"'.nr2char(getchar()).'pi'

lua <<EOF
vim.g.scrollview_excluded_filetypes = { 'neo-tree' }
vim.g.scrollview_current_only = true
if not vim.g.loaded_scrollview then
    require('scrollview.contrib.gitsigns').setup()
end
EOF

lua require('goto-preview').setup { default_mappings = true }

command! -nargs=+ WithIsk call WithIsk(<f-args>)
function! WithIsk(add_chars, remove_chars, cmd)
    let l:orig_isk = &isk
    exe 'setl isk+=' . a:add_chars . ' isk-=' . a:remove_chars . ' | ' . a:cmd
    let &isk = l:orig_isk
endfunction

inoremap <C-del> <C-o>de | inoremap <C-bs> <C-w>

lua << EOF
if vim.g.loaded_lsp_auto_complete then return end
vim.g.loaded_lsp_auto_complete = true

local ffi = require 'ffi'
ffi.cdef [[ bool pum_visible(); ]]
local pumvisible = ffi.C.pum_visible

vim.b.current_lsp_signature_help = 0
vim.b.lsp_signature_help_manual_mode = false

local original_convert_signature_help_to_markdown_lines = vim.lsp.util.convert_signature_help_to_markdown_lines
local function my_convert_signature_help_to_markdown_lines(signature_help, ft, triggers)
    if vim.b.lsp_signature_manual_mode then
        if #signature_help.signatures > 0 then
            vim.b.current_signature = vim.b.current_signature % #signature_help.signatures
        end
        signature_help.activeSignature = vim.b.current_signature
    else
        vim.b.current_signature = signature_help.activeSignature
    end
    for i, signature in ipairs(signature_help.signatures) do
        signature.label = signature.label .. "  (" .. i .. "/" .. #signature_help.signatures .. ")"
        if type(signature.documentation) == 'string' then
            signature.documentation = signature.documentation .. "\n\n**Current Parameter**\n"
        else
            signature.documentation.value = signature.documentation.value .. "\n\n**Current Parameter**\n"
        end
    end
    return original_convert_signature_help_to_markdown_lines(signature_help, ft, triggers)
end
vim.lsp.util.convert_signature_help_to_markdown_lines = my_convert_signature_help_to_markdown_lines

vim.api.nvim_create_autocmd('LspAttach', {
    callback = function(args)
        vim.lsp.completion.enable(true, args.data.client_id, args.buf, { autotrigger = true })
        vim.api.nvim_create_autocmd('CompleteChanged', {
            buffer = args.buf,
            callback = function()
                local info = vim.fn.complete_info({ 'selected' })

                local completionItem = vim.tbl_get(vim.v.completed_item, 'user_data', 'nvim', 'lsp', 'completion_item')
                if completionItem == nil then return end

                local resolvedItem = vim.lsp.buf_request_sync(
                    args.buf,
                    vim.lsp.protocol.Methods.completionItem_resolve,
                    completionItem,
                    500
                )
                if resolvedItem == nil then return end

                local docs = vim.tbl_get(resolvedItem[args.data.client_id], 'result', 'documentation', 'value')
                if docs == nil then return end

                local winData = vim.api.nvim__complete_set(info['selected'], { info = docs })
                if not winData.winid or not vim.api.nvim_win_is_valid(winData.winid) then return end

                vim.api.nvim_win_set_config(winData.winid, { border = 'rounded' })
                vim.treesitter.start(winData.bufnr, 'markdown')
                vim.wo[winData.winid].conceallevel = 3
            end
        })

        local client = vim.lsp.get_client_by_id(args.data.client_id)
        local completionTriggers = vim.tbl_get(client, 'server_capabilities', 'completionProvider', 'triggerCharacters') or
        {}
        local signatureHelpTriggers = vim.tbl_get(client, 'server_capabilities', 'signatureHelpProvider',
            'triggerCharacters') or {}
        local signatureHelpRetriggers = vim.tbl_get(client, 'server_capabilities',
            'signatureHelpProvider', 'retriggerCharacters') or {}

        function close_signature_help()
            local winid = vim.F.npcall(vim.api.nvim_buf_get_var, args.buf, 'lsp_floating_preview')
            vim.F.npcall(vim.api.nvim_win_close, winid, false)
            vim.b.lsp_signature_manual_mode = false
        end

        vim.lsp.handlers["textDocument/signatureHelp"] = vim.lsp.with(
            vim.lsp.handlers.signature_help,
            { max_height = 150, max_width = 120, close_events = { 'InsertLeave', 'CursorMoved' }, anchor_bias = 'above', border = 'rounded' }
        )

        vim.api.nvim_create_autocmd({ 'InsertLeave', 'CursorMoved' },
            { callback = function() vim.b.lsp_signature_manual_mode = false end })

        vim.api.nvim_create_autocmd('InsertCharPre', {
            buffer = args.buf,
            callback = function()
                if pumvisible() then return end
                if vim.v.char:match('[%w_]') and not vim.list_contains(completionTriggers, vim.v.char) then
                    vim.lsp.completion.trigger()
                end
                if vim.list_contains(signatureHelpTriggers, vim.v.char) then
                    vim.schedule(close_signature_help)
                    vim.schedule(vim.lsp.buf.signature_help)
                end
                if vim.list_contains(signatureHelpRetriggers, vim.v.char) then
                    vim.schedule(close_signature_help)
                end
            end,
        })

        local function nav_signature_help(dir)
            vim.b.current_signature = vim.b.current_signature + dir
            close_signature_help()
            vim.b.lsp_signature_manual_mode = true
            vim.lsp.buf.signature_help()
        end

        vim.keymap.set('i', '<C-S-j>', function() nav_signature_help(1) end)
        vim.keymap.set('i', '<C-S-k>', function() nav_signature_help(-1) end)
    end
})

vim.keymap.set('i', '<Tab>', function() return vim.fn.pumvisible() == 1 and '<C-n>' or '<Tab>' end,
    { expr = true })
vim.keymap.set('i', '<S-Tab>', function() return vim.fn.pumvisible() == 1 and '<C-p>' or '<S-Tab>' end,
    { expr = true })
vim.keymap.set('i', '<CR>', function() return vim.fn.pumvisible() == 1 and '<C-y>' or '<CR>' end, { expr = true })
EOF

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
