# ccrypt-wrapper.nvim

A Neovim plugin to encrypt and decrypt buffers with `ccrypt`.

![alt text](doc/images/ccrypt-wrapper.gif)

*ccrypt* is like *AES* and is based on the *Rijndael* cypher, and uses a
256-bit block size:

* Project page: [ccrypt](https://ccrypt.sourceforge.net)

# Prerequisites

* Neovim 0.10 or newer.
* *ccrypt* must be installed and in your path.

The password is passed to `ccrypt` through an environment variable
(`ccrypt -E`), so it never appears on a command line or in a temporary file.

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

Encrypts the buffer content in place using `ccrypt` with a password
(asked twice). The buffer is switched to `binary` mode so that `:w` writes
the exact ciphertext; the result can also be decrypted with
`ccrypt -d` on the command line. The undo history is cleared so the
plaintext cannot be restored with `u`.

#### Decrypt

Decrypts the buffer content in place using `ccrypt` with a password.
This also works for a `.cpt` file opened normally with `:e`.

#### EncryptFile

Encrypts the currently open buffer file using `ccrypt`.

1. Checks that the buffer is a named, non-`.cpt` file.
2. Prompts the user to enter and confirm an encryption password.
3. Writes the buffer to disk if it has unsaved changes.
4. Checks that the file is not empty.
5. Prompts for confirmation if the target file (`<file>.cpt`) already exists.
6. Uses `ccrypt` to encrypt the file in place, which renames it to
   `<file>.cpt` (no unencrypted copy is left behind).
7. Opens the encrypted file and wipes the plaintext buffer from memory.

#### DecryptFile

Decrypts the currently open `.cpt` file using `ccrypt`.

1. Validates that the current file has a `.cpt` extension and that the
   buffer has no unsaved changes (the file on disk is decrypted, not the
   buffer).
2. Prompts for confirmation if the decrypted file already exists.
3. Prompts the user to enter the decryption password.
4. Uses `ccrypt` to decrypt the file in place (removing `.cpt`).
5. Opens the decrypted file and wipes the encrypted buffer.

### ccrypt

If you have not installed `ccrypt`, you will receive this error message
when you call up the above functions:

```
ccrypt-wrapper: ccrypt is not installed.
```
