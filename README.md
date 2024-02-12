# PHP Use Sort

Neovim plugin to conveniently sort PHP "use" statements within your codebase. The plugin offers the flexibility to sort them alphabetically and by length, both in ascending and descending order.

## Features

- Sorts PHP "use" statements in your Neovim environment.
- Sorts PHP class properties in your Neovim environment.
- Supports sorting alphabetically and by statement length.
- Allows sorting in both ascending and descending order.
- Allows removing unused "use" statements.

## Usage

Execute the following command to sort your PHP "use" statements:

```vim
:PhpUseSort [alphabetical | length] [asc|desc]
```

## ⚡️ Requirements

- Neovim >= 0.5.0
- Treesitter >= 0.9.2

## 📦 Installation

Install the plugin with your preferred package manager:

### [lazy.nvim](https://github.com/folke/lazy.nvim)

```lua
{
  "ricardoramirezr/php-use-sort.nvim",
  dependencies = {
    "nvim-treesitter/nvim-treesitter",
  },
  ft = "php",
  opts = {
    order_by = "length",
    order = "asc",
    autocmd = true,
    rm_unused = true,
  },
  config = function(opts)
    require("php-use-sort").setup(opts)
    vim.keymap.set("n", "<leader>su", ":PhpUseSort<CR>", {
      desc = "Sort PHP use lines by length",
      silent = true,
    })
  end,
}
```

# ⚙️ Configuration

**php-use-sort.nvim** comes with the following defaults:

<!-- config:start -->

```lua
{
    order_by = "length", ---@type "length" | "alphabetical"
    order = "asc", ---@type "asc" | "desc"
    autocmd = false, -- create an autocmd group if true
    rm_unused = false, -- remove lines that "is declared but not used."
    includes = {
      uses = true,
      traits = true,
      properties = {
        enable = true,
        space = "between types", --- "none", "between properties"
    },
  },
}
```

<!-- config:end -->
