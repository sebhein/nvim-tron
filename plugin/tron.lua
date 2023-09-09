local api = vim.api
if not api.nvim_create_user_command then
  return
end

local cmd = api.nvim_create_user_command


cmd('tronRun', function() require('tron').run_test() end, {nargs = 0})
--cmd('tronShow', function() require('tron').show_output() end, {nargs = 0})
cmd('tronSplit', function() require('tron').run_test_in_split() end, {nargs = 0})
