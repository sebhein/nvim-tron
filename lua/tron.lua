-- Third party imports
local Job = require 'plenary.job'
local TestFile = require 'test_file'
local py_tree_search = require 'py_tree_search'
local utils = require 'utils'
local api = vim.api

local M = {
  _test_buffs = {},
}


local function get_test_file(bufnr)
  if M._test_buffs[bufnr] == nil then
    M._test_buffs[bufnr] = TestFile:new({bufnr=bufnr})
  end
  return M._test_buffs[bufnr]
end


function M.clear_signs()
  vim.fn.sign_unplace('TronSigns', {buffer=api.nvim_get_current_buf()})
end


function M.show_output()
  get_test_file(api.nvim_get_current_buf()):open_scratch()
end


function M.run_test()
  M.clear_signs()
  local bufnr = api.nvim_get_current_buf()
  local CurrentTestFile = get_test_file(bufnr)
  local test_names, maybe_one = py_tree_search.collect_test_names(bufnr)

  -- configure arguments to test runner
  local args = {
    'test',
    '--test-debug',
    CurrentTestFile:get_path(),
    '--',
    '-v',
    '--no-header'
  }
  if maybe_one then
    local function_name, _ = next(test_names)
    table.insert(args, '-k ' .. function_name)
  end

  local loading = utils.setup_notification(CurrentTestFile)

  -- Start Job
  Job:new({
    command = 'pants',
    args = args,
    on_stdout = function(j, data)
      if data:find('::') then
        local split_name = utils.split_string(data, '::')
        local tail = split_name[#split_name]
        local test_name = utils.split_string(tail, ' ')[1]
        local node = test_names[test_name]

        if node == nil then return end

        if data:find('FAILED') then
          CurrentTestFile:place_sign('TronFailure', test_name)
        else
          CurrentTestFile:place_sign('TronSuccess', test_name)
        end
      end
    end,
    on_exit = function(j, return_val)
      loading:stop()
      if return_val == 0 then
        utils.wrapped_notify(CurrentTestFile, '✓ All tests passed!', vim.log.levels.INFO)
      else
        utils.wrapped_notify(CurrentTestFile, '✗ One or more tests failed!', vim.log.levels.ERROR)
      end
      CurrentTestFile:write_to_scratch(j:result())
    end,
  }):start()
end


return M
