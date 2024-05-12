local Utils = {}

function Utils.table_changed(old_table, new_table)
  -- If the tables are not of the same type, they are considered changed
  if type(old_table) ~= type(new_table) then
    return true
  end

  -- If they are tables, recursively check each key-value pair
  if type(old_table) == "table" then
    -- Check for keys in old_table that are not in new_table
    for key, value in pairs(old_table) do
      if new_table[key] == nil then
        return true
      elseif Utils.table_changed(value, new_table[key]) then
        return true
      end
    end

    -- Check for keys in new_table that are not in old_table
    for key, _ in pairs(new_table) do
      if old_table[key] == nil then
        return true
      end
    end
    --
    -- If all key-value pairs match, return false
    return false
  end

  -- For non-table types, compare directly
  return old_table ~= new_table
end

function Utils.tablecopy(orig)
  local orig_type = type(orig)
  local copy
  if orig_type == "table" then
    copy = {}
    for orig_key, orig_value in next, orig, nil do
      copy[Utils.tablecopy(orig_key)] = Utils.tablecopy(orig_value)
    end
    setmetatable(copy, Utils.tablecopy(getmetatable(orig)))
  else -- number, string, boolean, etc
    copy = orig
  end
  return copy
end

---@diagnostic disable-next-line
Utils.p = function(value)
  print(vim.inspect(value))
end

---@diagnostic disable-next-line
Utils.t = function(node)
  if node == nil then
    return "nil"
  end
  Utils.p(ts.get_node_text(node, 0))
end

---@param range {min: number, max: number}
---@param statements table
function Utils.update_buffer(range, statements)
  local lines = {}
  for _, statement in pairs(statements) do
    for _, line in ipairs(statement.raw) do
      table.insert(lines, line)
    end
  end

  local success, err = pcall(vim.api.nvim_buf_set_lines, 0, range.min - 1, range.max, false, lines)
  if not success then
    vim.notify("Failed to update buffer: " .. err, vim.lsp.log_levels.ERROR)
  end
end

return Utils
