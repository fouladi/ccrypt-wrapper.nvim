# ccrypt-wrapper.nvim

A Neovim plugin to encrypt and decrypt buffers with `ccrypt`:
[ccrypt](https://ccrypt.sourceforge.net)

# Installation

Install the plugin with your package manager:

[lazy.nvim](https://github.com/folke/lazy.nvim):

```lua
{
    "fouladi/ccrypt-wrapper.nvim",
    config = function()
        require("ccrypt-wrapper").setup({})
    end,
}
```

# Usage

### Commands:

Custom commands `:Encrypt` and `:Decrypt` are defined to call these
functions.

### Key Mappings:

Optional key mappings are provided to quickly encrypt (<leader>ce) and
decrypt (<leader>cd) the buffer content.
