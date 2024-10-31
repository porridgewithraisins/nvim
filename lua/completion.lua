if vim.g.loaded_lsp_complete then return end
vim.g.loaded_lsp_complete = true

local ffi = require 'ffi'
ffi.cdef [[bool pum_visible();]]
local pumvisible = ffi.C.pum_visible
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

        vim.api.nvim_create_autocmd('InsertCharPre', {
            buffer = args.buf,
            callback = function()
                if pumvisible() then return end
                local client = vim.lsp.get_client_by_id(args.data.client_id)

                local triggers = vim.tbl_get(client, 'server_capabilities', 'completionProvider', 'triggerCharacters') or {}
                if vim.v.char:match('[%w_]') and not vim.list_contains(triggers, vim.v.char) then
                    vim.lsp.completion.trigger()
                end
            end,
        })

        require'goto-preview'.setup{ default_mappings = true }
    end
})

local pumMaps = {
  ['<Tab>'] = '<C-n>',
  ['<Down>'] = '<C-n>',
  ['<S-Tab>'] = '<C-p>',
  ['<Up>'] = '<C-p>',
  ['<CR>'] = '<C-y>',
}
for insertKmap, pumKmap in pairs(pumMaps) do
    vim.keymap.set(
        { 'i' },
        insertKmap,
        function ()
            return vim.fn.pumvisible() == 1 and pumKmap or insertKmap
        end,
        { expr = true }
    )
end
