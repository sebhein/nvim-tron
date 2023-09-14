local ts_utils = require 'nvim-treesitter.ts_utils'
local api = vim.api
local BufferObject = {}

function BufferObject:new(o)
  o = o or {}
  setmetatable(o, self)
  self.__index = self
  o.filename = api.nvim_buf_get_name(o.bufnr)
  o.scratch_bufnr = api.nvim_create_buf(false, true)
  api.nvim_buf_set_option(o.scratch_bufnr, 'filetype', 'terminal')
  o.test_names = {}
  o.notification_record = nil
  return o
end

function BufferObject:get_path()
  return self.filename
end

function BufferObject:reset_notification()
  self.notification_record = nil
end

function BufferObject:write_to_scratch(content)
  vim.schedule(function()
    api.nvim_buf_set_lines(self.scratch_bufnr, 0, -1, false, content)
  end)
end

function BufferObject:open_scratch()
  for _, winid in ipairs(vim.fn.getwininfo()) do
    if api.nvim_win_get_buf(winid.winid) == self.scratch_bufnr then
      return
    end
  end
  api.nvim_buf_call(self.scratch_bufnr, function()
    vim.cmd('botright vsplit')
    vim.cmd('vertical resize 100')
  end)
end

function BufferObject:collect_function_nodes(node, result)
    if node:type() == 'function_definition' then
      result[vim.treesitter.get_node_text(node:named_child(0), self.bufnr)] = node
    end

    for child in node:iter_children() do
        self:collect_function_nodes(child, result)
    end
end

function BufferObject:place_sign(type, function_name)
  vim.schedule(function()
    -- TODO: this seems pretty expensive to do for every sign
    local root = vim.treesitter.get_parser(self.bufnr):parse()[1]:root()
    local test_to_node = {}
    self:collect_function_nodes(root, test_to_node)
    -- this block
    local row, _, _ = test_to_node[function_name]:start()
    vim.fn.sign_place(0, 'TronSigns', type, self.bufnr, {lnum=row + 1, priority=10}) 
  end)
end

return BufferObject
