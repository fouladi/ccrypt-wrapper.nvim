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
and decrypting whole file.

#### Encrypt

Encrypts buffer content using `ccrypt` with a password.

#### Decrypt

Decrypts buffer content using `ccrypt` with a password.

#### EncryptFile

Encrypts the currently open buffer file using `ccrypt`.

1. Prompts the user to enter and confirm an encryption password.
2. Checks if the buffer is named and non-empty.
3. Writes the buffer to disk.
4. Prompts for confirmation if the target file (`<file>.cpt`) already exists.
5. Uses `ccrypt` to encrypt the file, which automatically appends `.cpt`.
6. Deletes the original unencrypted file after successful encryption.
7. Opens the encrypted file in the current buffer.

#### DecryptFile

Decrypts the currently open `.cpt` file using `ccrypt`.

1. Prompts the user to enter the decryption password.
2. Validates that the current file has a `.cpt` extension.
3. Writes the buffer to disk (to ensure content is current).
4. Uses `ccrypt` to decrypt the file in-place.
5. Automatically opens the decrypted file (with `.cpt` removed) in
   the buffer.

### ccrypt

If you have not installed `ccrypt`, you will receive this error message
when you call up the above functions:

```
Error: ccrypt is not installed.
```
