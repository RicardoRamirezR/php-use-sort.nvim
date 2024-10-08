local UseDeclarations = {}
local utils = require("php-use-sort.utils")

local ts = vim.treesitter
local vim_diagnostic = vim.diagnostic
UseDeclarations.skipped = false

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

local function extract_statements(qs, root, lang, rm_unused)
  local query = ts.query.parse(lang, qs)

  local use_statements = {}
  local range = { min = math.huge, max = 0 }

  for _, matches, _ in query:iter_matches(root, 0) do
    for _, node in pairs(matches) do
      local start_row, start_col, end_row, _ = node:range()

      range.min = math.min(range.min, start_row + 1)
      range.max = math.max(range.max, end_row + 1)

      if rm_unused and remove_declared_but_not_used(start_row) then
        UseDeclarations.skipped = true
      else
        local statement = string.rep(" ", start_col) .. ts.get_node_text(node, 0)
        local table_lines = {}
        local buff_lines = vim.api.nvim_buf_get_lines(0, start_row, end_row + 1, false)

        for _, buf_line in ipairs(buff_lines) do
          table.insert(table_lines, buf_line)
        end
        table.insert(use_statements, { statement = statement, node = node, raw = table_lines })
      end
    end
    ::continue::
  end

  return use_statements, range
end

local function sort_statements(use_statements, order_by, sort_order)
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

local function update_buffer(range, use_statements)
  local lines = {}
  for _, use_statement in pairs(use_statements) do
    table.insert(lines, use_statement.raw)
  end

  local success, err = pcall(vim.api.nvim_buf_set_lines, 0, range.min - 1, range.max, false, lines)
  if not success then
    vim.notify("Failed to update buffer: " .. err, vim.lsp.log_levels.ERROR)
  end
end

function UseDeclarations.sort(root, lang, options)
  local queries = {}

  if options.includes.traits then
    table.insert(queries, "(use_declaration) @trait")
  end

  if options.includes.uses then
    table.insert(queries, "(namespace_use_declaration) @use")
  end

  for _, query_string in ipairs(queries) do
    UseDeclarations.skipped = false
    local use_statements, range = extract_statements(query_string, root, lang, options.rm_unused)

    if next(use_statements) then
      local copied_table = utils.tablecopy(use_statements)

      sort_statements(use_statements, options.order_by, options.sort_order)

      if utils.table_changed(copied_table, use_statements) or UseDeclarations.skipped then
        utils.update_buffer(range, use_statements)
      end
    end
  end
end

return UseDeclarations
