# PHP Use Sort

Neovim plugin to conveniently sort PHP "use" statements within your codebase. The plugin offers the flexibility to sort them alphabetically and by length, both in ascending and descending order.

## Features

- Sorts PHP "use" statements in your Neovim environment.
- Supports sorting alphabetically and by statement length.
- Allows sorting in both ascending and descending order.
- Allows removing unused "use" statements.

## Usage

Execute the following command to sort your PHP "use" statements:

```vim
:PhpUseSort [asc|desc]
```

## ⚡️ Requirements

- Neovim >= 0.5.0

## 📦 Installation

Install the plugin with your preferred package manager:

### [lazy.nvim](https://github.com/folke/lazy.nvim)

```lua
{
  "ricardoramirezr/php-use-sort.nvim",
  ft = "php",
  opts = {
    order = "asc",
    autocmd = true,
    rm_unused = true,
  },
  config = function()
    require("php-use-sort").setup()
    vim.keymap.set("n", "<leader>su", ":PhpUseSort<CR>", { desc = "Sort PHP use lines by length", silent = true })
  end,
}
```

# ⚙️ Configuration

**php-use-sort.nvim** comes with the following defaults:

<!-- config:start -->

```lua
{
    order = "asc", ---@type "asc" | "desc"
    autocmd = false, -- create an autocmd group if true
    rm_unused = false, -- remove lines that "is declared but not used."
}
```

<!-- config:end -->
