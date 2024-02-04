# PHP Use Sort

Neovim plugin to conveniently sort PHP "use" statements within your codebase. The plugin offers the flexibility to sort them alphabetically and by length, both in ascending and descending order.

## Features

- Sorts PHP "use" statements in your Neovim environment.
- Supports sorting alphabetically and by statement length.
- Allows sorting in both ascending and descending order.

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
  config = function()
    require("php-use-sort").setup()
    vim.keymap.set("n", "<leader>su", ":PhpUseSort<CR>", { desc = "Sort PHP use lines by length", silent = true })
  end,
}
```

