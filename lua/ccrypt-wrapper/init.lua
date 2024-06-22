local M = {}

-- Function to encrypt buffer content using ccrypt with a password
M.encrypt_buffer = function()
    local password = vim.fn.inputsecret("Enter encryption password: ")
    if password == "" then
        print("Encryption aborted: No password provided.")
        return
    end

    local temp_file = vim.fn.tempname()
    vim.api.nvim_command("write! " .. temp_file)
    vim.api.nvim_command(
        "silent !echo " .. vim.fn.shellescape(password) .. " | ccrypt -e -K - " .. vim.fn.shellescape(temp_file)
    )
    if vim.fn.filereadable(temp_file .. ".cpt") == 1 then
        vim.api.nvim_command("silent edit! " .. temp_file .. ".cpt")
        vim.api.nvim_command(
            "silent !mv " .. vim.fn.shellescape(temp_file .. ".cpt") .. " " .. vim.fn.shellescape(temp_file)
        )
    else
        print("Encryption failed.")
    end
    os.remove(temp_file)
end

-- Function to decrypt buffer content using ccrypt with a password
M.decrypt_buffer = function()
    local password = vim.fn.inputsecret("Enter decryption password: ")
    if password == "" then
        print("Decryption aborted: No password provided.")
        return
    end

    local temp_file = vim.fn.tempname()
    vim.api.nvim_command("write! " .. temp_file)
    vim.api.nvim_command(
        "silent !echo " .. vim.fn.shellescape(password) .. " | ccrypt -d -K - " .. vim.fn.shellescape(temp_file)
    )
    if vim.fn.filereadable(temp_file) == 1 then
        vim.api.nvim_command("silent edit! " .. temp_file)
    else
        print("Decryption failed.")
    end
    os.remove(temp_file)
end

-- Setup function to define commands and key mappings
M.setup = function()
    vim.api.nvim_command('command! Encrypt lua require("ccrypt-wrapper").encrypt_buffer()')
    vim.api.nvim_command('command! Decrypt lua require("ccrypt-wrapper").decrypt_buffer()')
    vim.api.nvim_set_keymap("n", "<leader>ce", ":Encrypt<CR>", { noremap = true, silent = true })
    vim.api.nvim_set_keymap("n", "<leader>cd", ":Decrypt<CR>", { noremap = true, silent = true })
end

return M
