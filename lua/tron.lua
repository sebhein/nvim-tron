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
vim.fn.sign_define('TronFailure', {text='✗', linehl='TronFailure', texthl='TronFailure'})
vim.fn.sign_define('TronSuccess', {text='✓', linehl='TronSuccess', texthl='TronSuccess'})


local SPINNER = { '⣾', '⣽', '⣻', '⢿', '⡿', '⣟', '⣯', '⣷' }

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

function M.add_function_node(node, bufnr, tbl)
  if node:type() == 'function_definition' then
    tbl[vim.treesitter.get_node_text(node:named_child(0), bufnr)] = node
  end
end

function M.search_sibling_nodes(node, bufnr, tbl)
  while node do
    M.add_function_node(node, bufnr, tbl)
    node = node:next_sibling()
  end
end

function M.collect_test_names(bufnr)
  local node = ts_utils.get_node_at_cursor()
  local test_names = {}

  while node do
    M.add_function_node(node, bufnr, test_names)
    node = node:parent()
  end

  if next(test_names) then
    return test_names, true
  end

  local root = vim.treesitter.get_parser(bufnr):parse()[1]:root()
  local child = root:named_child(0)
  while child do
    if child:type() == 'decorated_definition' then
      M.search_sibling_nodes(child:next_sibling(), bufnr, test_names)
    end
    if child:type() == 'class_definition' then
      local body_child = child:named_child(child:named_child_count() - 1)
      M.search_sibling_nodes(body_child:named_child(0), bufnr, test_names)
    end
    M.add_function_node(child, bufnr, test_names)
    child = child:next_sibling()
  end

  return test_names, false
end

function M.get_test_file(bufnr)
  if M._test_buffs[bufnr] == nil then
    M._test_buffs[bufnr] = BufferObject:new({bufnr=bufnr})
  end
  return M._test_buffs[bufnr]
end

local wrapped_notify = vim.schedule_wrap(function(bo, msg, level, opts)
  local opts = {
    title='Tron Test Runner',
    replace=bo.notification_record,
    hide_from_history=true,
    keep=function() return true end,
  }
  if msg:find('✗') then
    opts['hide_from_history'] = false
    opts['timeout'] = 1000
    opts['keep'] = function() return false end
    opts['on_close'] = function()
      vim.schedule(function() bo:open_scratch() end)
    end
  elseif msg:find('✓') then
    opts['keep'] = function() return false end
    opts['hide_from_history'] = false
    opts['timeout'] = 5000
  end
  bo.notification_record = vim.notify(msg, level, opts)
end)

function M.run_test()
  M.clear_signs_in_current_buffer()
  local bufnr = api.nvim_get_current_buf()
  local CurrentTestFile = M.get_test_file(bufnr)
  local test_names, maybe_one = M.collect_test_names(bufnr)

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

  -- Setup notification
  CurrentTestFile:reset_notification()
  local spinner_idx = 1
  local loading_timer = vim.loop.new_timer()
  loading_timer:start(0, 300, vim.schedule_wrap(function()
    spinner_idx = spinner_idx + 1
    if spinner_idx > #SPINNER then spinner_idx = 1 end
    wrapped_notify(CurrentTestFile, SPINNER[spinner_idx] .. ' Running tests...', vim.log.levels.INFO)
  end))

  -- Start Job
  Job:new({
    command = 'pants',
    args = args,
    on_stdout = function(j, data)
      if data:find('::') then
        local split_name = M.split_string(data, '::')
        local tail = split_name[#split_name]
        local test_name = M.split_string(tail, ' ')[1]
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
      loading_timer:stop()
      if return_val == 0 then
        wrapped_notify(CurrentTestFile, '✓ All tests passed!', vim.log.levels.INFO)
      else
        wrapped_notify(CurrentTestFile, '✗ One or more tests failed!', vim.log.levels.ERROR)
      end
      CurrentTestFile:write_to_scratch(j:result())
    end,
  }):start()
end

function M.show_output()
  M.get_test_file(api.nvim_get_current_buf()):open_scratch()
end

return M
