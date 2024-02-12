local Config = {}

Config.namespace = vim.api.nvim_create_namespace("PhpUseSort")

---@class Options
---@field public order_by string
---@field public order string
local defaults = {
  order_by = "length",
  order = "asc",
  includes = {
    uses = true,
    traits = true,
    properties = {
      enable = true,
      space = "between types", --- "none", "between properties"
    },
  },
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
