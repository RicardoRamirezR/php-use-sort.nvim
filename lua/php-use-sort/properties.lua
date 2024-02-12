local Properties = {}

local ts = vim.treesitter

local function update_buffer(range, statements)
  local lines = {}
  for _, statement in pairs(statements) do
    table.insert(lines, statement.raw)
  end

  local success, err = pcall(vim.api.nvim_buf_set_lines, 0, range.min - 1, range.max, false, lines)
  if not success then
    vim.notify("Failed to update buffer: " .. err, vim.lsp.log_levels.ERROR)
  end
end

local qs = [[
  (property_declaration
    (visibility_modifier) @vis
    (static_modifier)? @modifier
    (property_element) @property_element
  ) @prop
  (const_declaration
    (visibility_modifier) @vis
    "const" @modifier
    (const_element) @property_element
  ) @prop
]]

local function extract_properties_declarations(root, query)
  local lines = {}
  local range = { min = math.huge, max = 0 }

  for _, match, _ in query:iter_matches(root, 0) do
    local line = { "", "", "", "", "", "" }
    for id, node in pairs(match) do
      line[id] = ts.get_node_text(node, 0)
      if id == 4 then
        local start_row, _, end_row, _ = node:range()
        range.min = math.min(range.min, start_row + 1)
        range.max = math.max(range.max, end_row + 1)
        line["raw"] = vim.api.nvim_buf_get_lines(0, start_row, end_row + 1, false)[1]
      end
    end
    table.insert(lines, line)
  end

  return lines, range
end

-- Define a function to compare two elements
local function compare(a, b)
  -- Sort by statics first
  if a[2] == "const" and b[2] ~= "const" then
    return true
  elseif a[2] ~= "const" and b[2] == "const" then
    return false
  end

  if a[2] == "static" and b[2] ~= "static" then
    return true
  elseif a[2] ~= "static" and b[2] == "static" then
    return false
  end

  -- If both are static or both are not static, sort by access modifier
  local access_order = { ["private"] = 1, ["protected"] = 2, ["public"] = 3 }
  if access_order[a[1]] ~= access_order[b[1]] then
    return access_order[a[1]] < access_order[b[1]]
  end

  -- If access modifiers are the same, sort by property name
  return a[3] < b[3]
end

function Properties.sort(root, lang, options)
  if not options.enable then
    return
  end

  local query = ts.query.parse(lang, qs)
  local lines, range = extract_properties_declarations(root, query)

  table.sort(lines, compare)

  if options.space == "between properties" then
    local lines_with = {}
    for _, line in ipairs(lines) do
      table.insert(lines_with, { raw = line.raw })
      table.insert(lines_with, { raw = "" })
    end
    lines = lines_with
  end

  if options.space == "between types" then
    local type = lines[1][1]
    local lines_with = {}
    for _, line in ipairs(lines) do
      if type ~= line[1] then
        type = line[1]
        table.insert(lines_with, { raw = "" })
      end
      table.insert(lines_with, { raw = line.raw })
    end
    lines = lines_with
  end

  update_buffer(range, lines)
end

return Properties
