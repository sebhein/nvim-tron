require 'terminal'.setup()

-- create autocommands
local api = vim.api
if not api.nvim_create_user_command then
  return
end
local cmd = api.nvim_create_user_command

cmd('TronRun', function() require('tron').run_test() end, {nargs = 0})
cmd('TronShow', function() require('tron').show_output() end, {nargs = 0})
cmd('TronClear', function() require('tron').clear_signs() end, {nargs = 0})

-- Define signs and mappings
api.nvim_set_hl(0, 'TronFailure', {fg='#ff0000'})
api.nvim_set_hl(0, 'TronSuccess', {fg='#00ff00'})
vim.fn.sign_define('TronFailure', {text='✗', linehl='TronFailure', texthl='TronFailure'})
vim.fn.sign_define('TronSuccess', {text='✓', linehl='TronSuccess', texthl='TronSuccess'})
