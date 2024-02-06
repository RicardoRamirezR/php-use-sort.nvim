---@class PhpUseSort
local PhpUseSort = {}

local ts = vim.treesitter
local parsers = require("nvim-treesitter.parsers")
local vim_diagnostic = vim.diagnostic

local p = function(value)
  print(vim.inspect(value))
end

local t = function(node)
  p(ts.get_node_text(node, 0))
end

local function sort_use_statements(use_statements, order_by, sort_order)
  if order_by == "alphabetical" then
    table.sort(use_statements, function(a, b)
      if sort_order == "desc" then
        return a.statement > b.statement
      end
      return a.statement < b.statement
    end)
    return
  end

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

local function remove_declared_but_not_used(row)
  local diag_text = "is declared but not used."
  local diagnostics = vim_diagnostic.get(0, {
    lnum = row,
    severity = vim_diagnostic.severity.HINT,
  })

  if not vim.tbl_isempty(diagnostics) and string.find(diagnostics[1].message, diag_text) then
    return true
  end

  return false
end

local function parse_tree(parser)
  return parser:parse()[1]
end

local function extract_use_statements(root, lang, rm_unused)
  local qs = [[ (namespace_use_declaration) @use ]]
  local query = ts.query.parse(lang, qs)

  local use_statements = {}
  local range = { min = math.huge, max = 0 }

  for _, matches, _ in query:iter_matches(root, 0) do
    for _, node in pairs(matches) do
      local start_row, _, end_row, _ = node:range()

      range.min = math.min(range.min, start_row + 1)
      range.max = math.max(range.max, end_row + 1)

      if not rm_unused or not remove_declared_but_not_used(start_row) then
        local statement = ts.get_node_text(node, 0)
        table.insert(use_statements, { statement = statement, node = node })
      end
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

local function get_completions(context)
  local completions = {}
  local words = vim.split(context, "%s")
  local current_word = words[#words] or ""

  if #words == 2 and current_word == "" then
    completions = { "length", "alphabetical" }
  elseif #words == 3 and current_word == "" then
    completions = { "asc", "desc" }
  end

  return completions
end

local function setup_command()
  vim.api.nvim_create_user_command("PhpUseSort", function(opts)
    local args = vim.split(opts.args, "%s")
    local order_by = args[1] or ""
    local sort_order = args[2] or ""

    PhpUseSort.main(order_by, sort_order)
  end, {
    nargs = "?",
    complete = function(_, _, _)
      local context = vim.fn.getcmdline()

      if context ~= nil then
        return get_completions(context)
      else
        return {}
      end
    end,
    desc = "Sort PHP use lines by length or alphabetical order. Accepts sorting options.",
  })
end

--     complete = "custom,ListUsers",
-- local function ListUsers(A, L, P)
--   return { "asc", "desc" }
-- end

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

  local use_statements, range = extract_use_statements(root, lang, options.rm_unused)

  sort_order = sort_order ~= "" and sort_order or options.order
  order_by = order_by ~= "" and order_by or options.order_by

  sort_use_statements(use_statements, order_by, sort_order)

  update_buffer(range, use_statements)
end

function PhpUseSort.setup(options)
  require("php-use-sort.config").setup(options.opts)
  setup_command()
  setup_autocmd()
end

return PhpUseSort
