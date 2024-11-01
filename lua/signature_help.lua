if vim.g.loaded_auto_signature_help then return end
vim.g.loaded_auto_signature_help = true

vim.b.current_signature = 0
vim.b.lsp_signature_manual_mode = false
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
        signature.label = "(" .. i .. "/" .. #signature_help.signatures .. ")\n" .. signature.label
    end
    return original_convert_signature_help_to_markdown_lines(signature_help, ft, triggers)
end
vim.lsp.util.convert_signature_help_to_markdown_lines = my_convert_signature_help_to_markdown_lines

local lsp_complete_group = vim.api.nvim_create_augroup('auto_signature_help', { clear = false })

vim.api.nvim_create_autocmd('LspAttach', {
    group = lsp_complete_group,
    pattern = '<buffer>',
    callback = function(args)
        local function get_signature_help_window()
            local winid = vim.F.npcall(vim.api.nvim_buf_get_var, args.buf, 'lsp_floating_preview')
            if winid and vim.api.nvim_win_is_valid(winid) then
                return winid
            end
            return nil
        end
        local function close_signature_help()
            local winid = get_signature_help_window()
            if winid ~= nil then
                vim.api.nvim_win_close(winid, false)
            end
            vim.b.lsp_signature_manual_mode = false
        end

        vim.lsp.handlers["textDocument/signatureHelp"] = vim.lsp.with(
            vim.lsp.handlers.signature_help,
            { max_height = 80, max_width = 80, close_events = { 'InsertLeave', 'CursorMoved' }, anchor_bias = 'above' }
        )

        vim.api.nvim_create_autocmd({ 'InsertLeave', 'CursorMoved' },
            { callback = function() vim.b.lsp_signature_manual_mode = false end })

        vim.api.nvim_create_autocmd('TextChangedI', {
            group = lsp_complete_group,
            pattern = '<buffer>',
            callback = function()
                local client = vim.lsp.get_client_by_id(args.data.client_id)
                if not client then return end
                local signatureHelpTriggers = vim.tbl_get(client, 'server_capabilities', 'signatureHelpProvider',
                    'triggerCharacters') or {}
                local signatureHelpRetriggers = vim.tbl_get(client, 'server_capabilities',
                    'signatureHelpProvider', 'retriggerCharacters') or {}

                local pos, line = vim.api.nvim_win_get_cursor(0), vim.api.nvim_get_current_line()
                local last_character = line:sub(pos[2], pos[2])
                if vim.list_contains(signatureHelpTriggers, last_character) then
                    close_signature_help()
                    vim.lsp.buf.signature_help()
                end

                if vim.list_contains(signatureHelpRetriggers, last_character) then
                    close_signature_help()
                end
            end
        })

        local function next_signature_help(keys)
            if get_signature_help_window() ~= nil then
                vim.b.current_signature = vim.b.current_signature + 1
                close_signature_help()
                vim.b.lsp_signature_manual_mode = true
                vim.lsp.buf.signature_help()
            else
                return keys
            end
        end

        local function prev_signature_help(keys)
            if get_signature_help_window() ~= nil then
                vim.b.current_signature = vim.b.current_signature - 1
                close_signature_help()
                vim.b.lsp_signature_manual_mode = true
                vim.lsp.buf.signature_help()
            else
                return keys
            end
        end

        vim.keymap.set('i', '<c-k>', function() return prev_signature_help('<c-k>') end)
        vim.keymap.set('i', '<c-j>', function() return next_signature_help('<c-j>') end)
    end
})
