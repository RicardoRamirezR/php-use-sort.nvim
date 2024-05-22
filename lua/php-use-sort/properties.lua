local utils = require("php-use-sort.utils")
local ts = vim.treesitter
local ts_utils = require("nvim-treesitter.ts_utils")

local Properties = {}

local function get_comments(property, range)
  local node = ts_utils.get_previous_node(property, false, false)
  local comments = {}

  if not node or node:type() ~= "comment" then
    return comments
  end

  local start_row, _, end_row, _ = node:range()
  range.min = math.min(range.min, start_row + 1)
  range.max = math.max(range.max, end_row + 1)

  local lines = vim.api.nvim_buf_get_lines(0, start_row, end_row + 1, false)
  for _, line in ipairs(lines) do
    table.insert(comments, line)
  end

  return comments
end

local function extract_properties_declarations(class_body)
  local lines = {}
  local range = { min = math.huge, max = 0 }

  local property_query = [[
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

  local query = ts.query.parse("php", property_query)

  for _, match, _ in query:iter_matches(class_body, 0) do
    local line = { vis = "", modifier = "", element = "", raw = {} }
    for id, node in pairs(match) do
      local node_text = ts.get_node_text(node, 0)
      if id == 1 then
        line.vis = node_text
      elseif id == 2 then
        line.modifier = node_text
        if node_text == "const" then
          line.vis = line.vis .. " const"
        end
      elseif id == 3 then
        line.element = node_text
      end

      if id == 4 then
        local start_row, _, end_row, _ = node:range()
        range.min = math.min(range.min, start_row + 1)
        range.max = math.max(range.max, end_row + 1)
        line.raw = get_comments(node, range)
        local element_lines = vim.api.nvim_buf_get_lines(0, start_row, end_row + 1, false)
        for _, element_line in ipairs(element_lines) do
          table.insert(line.raw, element_line)
        end
      end
    end
    table.insert(lines, line)
  end

  return lines, range
end

local function compare_properties(a, b)
  -- Sort by constant first
  if a.modifier == "const" and b.modifier ~= "const" then
    return true
  elseif a.modifier ~= "const" and b.modifier == "const" then
    return false
  end

  -- Sort by statics first
  if a.modifier == "static" and b.modifier ~= "static" then
    return true
  elseif a.modifier ~= "static" and b.modifier == "static" then
    return false
  end

  -- If both are static or both are not static, sort by access modifier
  local access_order = { ["private"] = 1, ["protected"] = 2, ["public"] = 3 }
  if access_order[a.vis] ~= access_order[b.vis] then
    return access_order[a.vis] < access_order[b.vis]
  end

  -- If access modifiers are the same, sort by property name
  return a.element < b.element
end

local function sort_properties(properties, range, options)
  local original_properties = utils.tablecopy(properties)
  table.sort(properties, compare_properties)

  if not utils.table_changed(original_properties, properties) then
    return
  end

  if options.space == "between properties" then
    local properties_with_spaces = {}
    for _, line in ipairs(properties) do
      table.insert(properties_with_spaces, { raw = line.raw })
      table.insert(properties_with_spaces, { raw = { "" } })
    end
    properties = properties_with_spaces
  end

  if options.space == "between types" then
    local previous_type = properties[1].modifier
    local spaced_properties = {}
    for _, property in ipairs(properties) do
      if property.modifier ~= previous_type then
        table.insert(spaced_properties, { raw = { "" } })
        previous_type = property.modifier
      end
      table.insert(spaced_properties, { raw = property.raw })
    end
    properties = spaced_properties
  end

  utils.update_buffer(range, properties)
end

function Properties.sort(root, lang, options)
  if not options.enable then
    return
  end

  local query = ts.query.parse(lang, "((class_declaration) @class)")
  local class_properties = {}

  for _, node, _ in query:iter_captures(root, 0) do
    if node:type() == "class_declaration" then
      local properties, range = extract_properties_declarations(node)
      if next(properties) then
        table.insert(class_properties, { properties = properties, range = range })
      end
    end
  end

  for i = #class_properties, 1, -1 do
    local class_info = class_properties[i]
    sort_properties(class_info.properties, class_info.range, options)
  end
end

return Properties
