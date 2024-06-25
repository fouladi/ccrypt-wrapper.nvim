# ccrypt-wrapper.nvim

A Neovim plugin to encrypt and decrypt buffers with `ccrypt`. It is like
*AES* and is based on the *Rijndael* cypher, and uses a 256-bit block size.

* Project page: [ccrypt](https://ccrypt.sourceforge.net)

# Prerequisite for installation:

You must have *ccrypt* installed and it must be in your path.

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

After setup, the following commands will be automatically applied.

### Commands:

Custom commands `:Encrypt` and `:Decrypt` are defined to call these
functions.

If you have not installed `ccrypt`, you will receive this error message
when you call up the above functions:

```
Error: ccrypt is not installed.
```

### Key Mappings:

Optional key mappings are provided to quickly encrypt (`<leader>ce`) and
decrypt (`<leader>cd`) the buffer content.
