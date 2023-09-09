-- Third party imports
local ts_utils = require 'nvim-treesitter.ts_utils'
local Job = require 'plenary.job'

local M = {}

-- Define signs and mappings
vim.api.nvim_set_hl(0, 'Failure', {fg='#ff0000'})
vim.api.nvim_set_hl(0, 'Success', {fg='#00ff00'})
vim.fn.sign_define('Failure', {text='✗', texthl='Failure'})
vim.fn.sign_define('Success', {text='✓', texthl='Success'})


function M.place_sign(type, bufnr, row)
  vim.schedule(function()
    vim.fn.sign_place(0, 'testa', type, bufnr, {lnum=row + 1, priority=10}) 
  end)
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
  local function_name, row = nil, nil

  while node do
    if node:type() == 'function_definition' then
      function_name = vim.treesitter.get_node_text(node:named_child(0), bufnr)
      row, _, _ = node:start()
      test_names[function_name] = row
    end
    node = node:parent()
  end

  if function_name then
    test_names[function_name] = row
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
            local row, _, _ = sibling:start()
            test_names[function_name] = row
          end
          sibling = sibling:next_sibling()
        end
      elseif child:type() == 'function_definition' then
        local function_name = vim.treesitter.get_node_text(child:named_child(0), bufnr)
        local row, _, _ = child:start()
        test_names[function_name] = row
      end
      child = child:next_sibling()
    end
  end

  return test_names, false
end

function M.run_test()
  local bufnr = vim.api.nvim_get_current_buf()
  local test_names, maybe_one = M.collect_test_names(bufnr)
  local args = {
    'test',
    '--test-debug',
    vim.api.nvim_buf_get_name(bufnr),
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
        local row = test_names[test_name]
        if row == nil then goto continue end
        if data:find('FAILED') then
          M.place_sign('Failure', bufnr, test_names[test_name])
        else
          M.place_sign('Success', bufnr, test_names[test_name])
        end
        ::continue::
      end
    end,
    --on_exit = function(j, return_val)
      ----print(return_val)
      ----print(vim.inspect(j:result()))
    --end,
  }):sync() -- or start()
end

function M.write_to_temp_buff(buff, content)
  vim.schedule(function()
    vim.api.nvim_buf_set_lines(buff, -1, -1, false, content)
  end)
end

function M.run_test_in_split()
  local bufnr = vim.api.nvim_get_current_buf()
  local test_names, maybe_one = M.collect_test_names(bufnr)
  local newbuf = vim.api.nvim_create_buf(false, true)
  local args = {
    'test',
    '--test-debug',
    vim.api.nvim_buf_get_name(bufnr),
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
    on_exit = function(j, return_val)
      M.write_to_temp_buff(newbuf, j:result())
    end,
  }):sync() -- or start()

  vim.api.nvim_buf_call(newbuf, function()
    vim.cmd('botright vsplit')
    vim.cmd('vertical resize 120')
  end)
end

return M
