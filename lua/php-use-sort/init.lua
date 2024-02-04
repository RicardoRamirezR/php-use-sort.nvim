local ts = vim.treesitter
local parsers = require("nvim-treesitter.parsers")

local p = function(value)
  print(vim.inspect(value))
end

local t = function(node)
  p(ts.get_node_text(node, 0))
end

---@class PhpUseSort
local M = {}

local function sort_use_statements(use_statements, sort_order)
  table.sort(use_statements, function(a, b)
    local len_a, len_b = #a.statement, #b.statement

    if sort_order == "desc" then
      if len_a == len_b then
        return a.statement > b.statement
      end

      return len_a > len_b
    end

    if len_a == len_b then
      return a.statement < b.statement
    end

    return len_a < len_b
  end)
end

local function parse_tree(parser)
  return parser:parse()[1]
end

local function extract_use_statements(root, lang)
  local qs = [[ (namespace_use_declaration) @use ]]
  local query = ts.query.parse(lang, qs)

  local use_statements = {}
  local range = { min = math.huge, max = 0 }

  for _, matches, metadata in query:iter_matches(root, 0) do
    for _, node in pairs(matches) do
      local start_row, _, end_row, _ = node:range()
      local statement = ts.get_node_text(node, 0)
      table.insert(use_statements, { statement = statement, node = node })
      range.min = math.min(range.min, start_row + 1)
      range.max = math.max(range.max, end_row + 1)
    end
  end

  return use_statements, range
end

local function update_buffer(range, use_statements)
  local lines = {}
  for _, use_statement in pairs(use_statements) do
    table.insert(lines, use_statement.statement)
  end

  local success, err = pcall(vim.api.nvim_buf_set_lines, 0, range.min - 1, range.max, false, lines)
  if not success then
    vim.notify("Failed to update buffer: " .. err, vim.lsp.log_levels.ERROR)
  end
end

local function setup_autocmd()
  local Config = require("php-use-sort.config")
  if not Config.options.autocmd then
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
    M.main(opts.args)
  end, {
    nargs = "?",
    complete = function(_, _, _)
      return { "asc", "desc" }
    end,
    desc = "Sort PHP use lines by length. Accepts sorting options.",
  })
end

function M.main(sort_order)
  local Config = require("php-use-sort.config")
  local parser = parsers.get_parser()
  local tree = parse_tree(parser)

  if not parser or not tree then
    vim.notify("Failed to parse the tree.", vim.lsp.log_levels.ERROR)
    return
  end

  local root = tree:root()
  local lang = parser:lang()

  if lang ~= "php" then
    print("Info: works only on PHP.")
    return
  end

  sort_order = sort_order ~= "" and sort_order or Config.options.order

  local use_statements, range = extract_use_statements(root, lang)

  sort_use_statements(use_statements, sort_order)

  update_buffer(range, use_statements)
end

function M.setup(options)
  require("php-use-sort.config").setup(options.opts)
  setup_command()
  setup_autocmd()
end

return M
