---@class PhpUseSort
local PhpUseSort = {}

local ts = vim.treesitter
local parsers = require("nvim-treesitter.parsers")

---@diagnostic disable-next-line
local p = function(value)
  print(vim.inspect(value))
end

---@diagnostic disable-next-line
local t = function(node)
  p(ts.get_node_text(node, 0))
end

local function parse_tree(parser)
  return parser:parse()[1]
end

function PhpUseSort.get_config_options()
  return require("php-use-sort.config").options
end

function PhpUseSort.main(order_by, sort_order)
  if not vim.bo.filetype:find("php", 1, true) then
    return
  end

  local parser = parsers.get_parser()

  if not parser then
    vim.notify("Failed to parse the tree.", vim.lsp.log_levels.ERROR)
    return
  end

  local tree = parse_tree(parser)

  if not tree then
    vim.notify("Failed to parse the tree.", vim.lsp.log_levels.ERROR)
    return
  end

  local root = tree:root()
  local lang = parser:lang()

  if lang ~= "php" then
    print("Info: works only on PHP.")
    return
  end

  local options = PhpUseSort.get_config_options()

  options.order = sort_order ~= "" and sort_order or options.order
  options.order_by = order_by ~= "" and order_by or options.order_by

  require("php-use-sort.use_declarations").sort(root, lang, options)
  require("php-use-sort.properties").sort(root, lang, options.includes.properties)
end

function PhpUseSort.setup(options)
  require("php-use-sort.config").setup(options.opts)
  require("php-use-sort.commands").setup(PhpUseSort.main)
end

return PhpUseSort
