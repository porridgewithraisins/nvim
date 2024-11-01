
local timer_n, timer_i
local timeout = 100

local function cursor_hold(mode, cmd)
    if vim.api.nvim_get_mode().mode ~= mode then return end
    vim.opt.eventignore:remove(cmd)
    vim.api.nvim_exec_autocmds(cmd, {})
    vim.opt.eventignore:append(cmd)
end

local function cursor_move(t, callback)
  if t == nil or t:is_closing() then
    t = vim.defer_fn(callback, timeout)
  else
    t:stop()
    t:start(timeout, 0, vim.schedule_wrap(callback))
  end
  return t
end

vim.opt.eventignore:append("CursorHold")
local g = vim.api.nvim_create_augroup("custom_hold", { clear = true })
vim.api.nvim_create_autocmd("CursorMoved", {
  callback = function()
    timer_n = cursor_move(timer_n, function() cursor_hold("n", "CursorHold") end)
  end,
  group = g
})
vim.api.nvim_create_autocmd("CursorMovedI", {
  callback = function()
    timer_i = cursor_move(timer_i, function() cursor_hold("i", "CursorHoldI") end)
  end,
  group = g
})
