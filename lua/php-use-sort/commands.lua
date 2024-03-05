local Commands = {}

local function setup_autocmd()
  local options = require("php-use-sort.config").options
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

local function setup_command(main)
  vim.api.nvim_create_user_command("PhpUseSort", function(opts)
    local args = vim.split(opts.args, "%s+")
    local order_by = args[1] or ""
    local sort_order = args[2] or ""

    main(order_by, sort_order)
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

function Commands.setup(main)
  setup_autocmd()
  setup_command(main)
end

return Commands
