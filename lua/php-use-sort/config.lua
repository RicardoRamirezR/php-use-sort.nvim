local Config = {}

Config.namespace = vim.api.nvim_create_namespace("PhpUseSort")

---@class Options
local defaults = {
  order_by = "length",
  order = "asc",
  autocmd = false,
  rm_unused = false,
}

---@type Options
Config.options = {}

---@param options? Options
function Config.setup(options)
  Config.options = vim.tbl_deep_extend("force", {}, defaults, options or {})
end

Config.setup()

return Config
