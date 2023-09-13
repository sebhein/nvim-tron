require 'terminal'.setup()

local api = vim.api
if not api.nvim_create_user_command then
  return
end

local cmd = api.nvim_create_user_command

cmd('TronRun', function() require('tron').run_test() end, {nargs = 0})
cmd('TronShow', function() require('tron').show_output() end, {nargs = 0})
cmd('TronClear', function() require('tron').clear_signs_in_current_buffer() end, {nargs = 0})

