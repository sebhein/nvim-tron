-- Third party imports
local ts_utils = require 'nvim-treesitter.ts_utils'
local Job = require 'plenary.job'
local BufferObject = require 'buffer_object'
local api = vim.api

local M = {
  _test_buffs = {},
}

-- Define signs and mappings
api.nvim_set_hl(0, 'TronFailure', {fg='#ff0000'})
api.nvim_set_hl(0, 'TronSuccess', {fg='#00ff00'})
vim.fn.sign_define('TronFailure', {text='✗', texthl='TronFailure'})
vim.fn.sign_define('TronSuccess', {text='✓', texthl='TronSuccess'})



function M.clear_signs_in_current_buffer()
  vim.fn.sign_unplace('TronSigns', {buffer=api.nvim_get_current_buf()})
end

function M.split_string(to_split, seperator)
  local result={}
  for chunk in string.gmatch(to_split, "([^"..seperator.."]+)") do
    table.insert(result, chunk)
  end
  return result
end

function M.collect_test_names(bufnr)
  local node = ts_utils.get_node_at_cursor()
  local test_names = {}

  while node do
    if node:type() == 'function_definition' then
      local function_name = vim.treesitter.get_node_text(node:named_child(0), bufnr)
      test_names[function_name] = node
    end
    node = node:parent()
  end

  if next(test_names) then
    return test_names, true
  end
  
  if next(test_names) == nil then
    local root = ts_utils.get_root_for_position(0, 0)
    local child = root:named_child(0)
    while child do
      if child:type() == 'decorated_definition' then
        local sibling = child:named_child(0)
        while sibling do
          if sibling:type() == 'function_definition' then
            local function_name = vim.treesitter.get_node_text(sibling:named_child(0), bufnr)
            test_names[function_name] = sibling
          end
          sibling = sibling:next_sibling()
        end
      elseif child:type() == 'function_definition' then
        local function_name = vim.treesitter.get_node_text(child:named_child(0), bufnr)
        test_names[function_name] = child
      end
      child = child:next_sibling()
    end
  end

  return test_names, false
end

function M.get_test_file(bufnr)
  if M._test_buffs[bufnr] == nil then
    M._test_buffs[bufnr] = BufferObject:new(bufnr)
  end
  return M._test_buffs[bufnr]
end

local wrapped_notify = vim.schedule_wrap(function(msg, level) vim.notify(msg, level) end)

function M.run_test()
  M.clear_signs_in_current_buffer()
  local bufnr = api.nvim_get_current_buf()
  local CurrentTestFile = M.get_test_file(bufnr)

  local test_names, maybe_one = M.collect_test_names(bufnr)
  local args = {
    'test',
    '--test-debug',
    CurrentTestFile:get_path(),
    '--',
    '-v',
    '-s',
    '--no-header'
  }

  if maybe_one then
    local function_name, _ = next(test_names)
    table.insert(args, '-k ' .. function_name)
  end

  Job:new({
    command = 'pants',
    args = args,
    on_stdout = function(j, data)
      if data:find('::') then
        local test_name = M.split_string(M.split_string(data, '::')[2], ' ')[1]
        local node = test_names[test_name]
        if node == nil then goto continue end
        if data:find('FAILED') then
          CurrentTestFile:place_sign('TronFailure', test_name)
        else
          CurrentTestFile:place_sign('TronSuccess', test_name)
        end
        ::continue::
      end
    end,
    on_exit = function(j, return_val)
      if return_val == 0 then
        wrapped_notify('✓ All tests passed!', vim.log.levels.INFO)
      else
        wrapped_notify('✗ One or more tests failed!', vim.log.levels.ERROR)
      end
      CurrentTestFile:write_to_scratch(j:result())
      --print(return_val)
      --print(vim.inspect(j:result()))
    end,
  }):start()
end

function M.show_output()
  local CurrentTestFile = M.get_test_file(api.nvim_get_current_buf())
  CurrentTestFile:open_scratch()
end

return M
