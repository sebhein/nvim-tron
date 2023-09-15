local ts_utils = require 'nvim-treesitter.ts_utils'

local M = {}

local function add_function_node(node, bufnr, tbl)
  if node:type() == 'function_definition' then
    tbl[vim.treesitter.get_node_text(node:named_child(0), bufnr)] = node
  end
end

local function search_sibling_nodes(node, bufnr, tbl)
  while node do
    add_function_node(node, bufnr, tbl)
    node = node:next_sibling()
  end
end

function M.collect_test_names(bufnr)
  local node = ts_utils.get_node_at_cursor()
  local test_names = {}

  while node do
    add_function_node(node, bufnr, test_names)
    node = node:parent()
  end

  if next(test_names) then
    return test_names, true
  end

  local root = vim.treesitter.get_parser(bufnr):parse()[1]:root()
  local child = root:named_child(0)
  while child do
    if child:type() == 'decorated_definition' then
      search_sibling_nodes(child:next_sibling(), bufnr, test_names)
    end
    if child:type() == 'class_definition' then
      local body_child = child:named_child(child:named_child_count() - 1)
      search_sibling_nodes(body_child:named_child(0), bufnr, test_names)
    end
    add_function_node(child, bufnr, test_names)
    child = child:next_sibling()
  end

  return test_names, false
end

return M
