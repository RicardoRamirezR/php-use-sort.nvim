local M = {}

M.namespace = vim.api.nvim_create_namespace("PhpUseSort")

---@class Options
local defaults = {
  order = "asc",
  autocmd = false,
  rm_unused = false,
}

---@type Options
M.options = {}

---@param options? Options
function M.setup(options)
  M.options = vim.tbl_deep_extend("force", {}, defaults, options or {})
end

M.setup()

return M
