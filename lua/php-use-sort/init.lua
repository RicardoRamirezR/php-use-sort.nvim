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

local function setup_autocmd()
  local options = PhpUseSort.get_config_options()
  if not options.autocmd then
    return
  end
  local group = vim.api.nvim_create_augroup("PhpUseSort", { clear = true })

  vim.api.nvim_create_autocmd("BufWritePre", {
    pattern = { "*.php" },
    command = "PhpUseSort",
    group = group,
  })
end

local function setup_command()
  vim.api.nvim_create_user_command("PhpUseSort", function(opts)
    local args = vim.split(opts.args, "%s+")
    local order_by = args[1] or ""
    local sort_order = args[2] or ""

    PhpUseSort.main(order_by, sort_order)
  end, {
    nargs = "?",
    complete = function(_, line)
      local order_by = { "alphabetical", "length" }
      local direction = { "asc", "desc" }

      local l = vim.split(line, "%s+")
      local n = #l - 2

      if n == 0 then
        return vim.tbl_filter(function(val)
          return vim.startswith(val, l[2])
        end, order_by)
      end

      if n == 1 then
        return vim.tbl_filter(function(val)
          return vim.startswith(val, l[3])
        end, direction)
      end
    end,
    desc = "Sort PHP use lines by length or alphabetical order. Accepts sorting options.",
  })
end

function PhpUseSort.get_config_options()
  return require("php-use-sort.config").options
end

function PhpUseSort.main(order_by, sort_order)
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
  setup_autocmd()
  setup_command()
end

return PhpUseSort
