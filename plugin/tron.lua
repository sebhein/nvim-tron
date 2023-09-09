local api = vim.api
if not api.nvim_create_user_command then
  return
end

local cmd = api.nvim_create_user_command

cmd('TronRun', function() require('tron').run_test() end, {nargs = 0})
--cmd('TronShow', function() require('tron').show_output() end, {nargs = 0})
cmd('TronSplit', function() require('tron').run_test_in_split() end, {nargs = 0})
