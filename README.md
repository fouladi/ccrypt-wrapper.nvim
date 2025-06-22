# ccrypt-wrapper.nvim

A Neovim plugin to encrypt and decrypt buffers with `ccrypt`.

![alt text](doc/images/ccrypt-wrapper.gif)

*ccrypt* is like *AES* and is based on the *Rijndael* cypher, and uses a
256-bit block size:

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

The commands `:Encrypt` and `:Decrypt` are defined to call `ccrypt` for
encrypting and decrypting the buffer.

The commands `:EncryptFile` and `:DecryptFile` call `ccrypt` to encrypt
and decrypting whole files.

If you have not installed `ccrypt`, you will receive this error message
when you call up the above functions:

```
Error: ccrypt is not installed.
```
