local M = {}

-- Function to check if "ccrypt" is installed
local function is_ccrypt_installed()
    local handle = io.popen("command -v ccrypt")
    if handle == nil then
        return false
    end

    local result = handle:read("*a")
    handle:close()

    if result == nil then
        return false
    end

    return result ~= ""
end

-- Function to encrypt buffer content using "ccrypt" with a password
M.encrypt_buffer = function()
    if not is_ccrypt_installed() then
        print("Error: ccrypt is not installed.")
        return
    end

    -- Prompt for password twice
    local password1 = vim.fn.inputsecret("Enter encryption password: ")
    local password2 = vim.fn.inputsecret("Repeat encryption password: ")

    if password1 == "" or password2 == "" then
        print("Encryption aborted: Password cannot be empty.")
        return
    end

    if password1 ~= password2 then
        print("Encryption aborted: Passwords do not match.")
        return
    end

    -- Save current buffer
    vim.cmd("write")

    -- Get full path and output path
    local original_path = vim.api.nvim_buf_get_name(0)
    if original_path == "" then
        print("Encryption aborted: Buffer has no name. Save it first.")
        return
    end

    local cp_path = original_path .. ".cp"

    -- Encrypt using password file
    local command = string.format(
        "ccrypt -e -k %s -o %s %s",
        vim.fn.shellescape(passfile),
        vim.fn.shellescape(cp_path),
        vim.fn.shellescape(original_path)
    )
    local result = os.execute(command)

    if result == 0 then
        print("Encrypted successfully to: " .. cp_path)
        vim.cmd("edit " .. cp_path)
    else
        print("Encryption failed.")
    end
end

-- Function to decrypt buffer content using "ccrypt" with a password
M.decrypt_buffer = function()
    if not is_ccrypt_installed() then
        print("Error: ccrypt is not installed.")
        return
    end

    -- Get password
    local password = vim.fn.inputsecret("Enter decryption password: ")
    if password == "" then
        print("Decryption aborted: No password provided.")
        return
    end

    -- Save current buffer
    vim.cmd("write")

    local encrypted_path = vim.api.nvim_buf_get_name(0)
    if encrypted_path == "" or not encrypted_path:match("%.cp$") then
        print("File does not look like a '.cp' encrypted file.")
        return
    end

    local decrypted_path = encrypted_path:gsub("%.cp$", "")

    -- Run ccrypt to decrypt to original name
    local command = string.format(
        "echo %s | ccrypt -d -K - -o %s %s",
        vim.fn.shellescape(password),
        vim.fn.shellescape(decrypted_path),
        vim.fn.shellescape(encrypted_path)
    )
    local result = os.execute(command)

    if result == 0 then
        print("Decrypted to: " .. decrypted_path)
        vim.cmd("edit " .. decrypted_path)
    else
        print("Decryption failed.")
    end
end

-- Setup function to define commands and key mappings
M.setup = function()
    vim.api.nvim_command('command! Encrypt lua require("ccrypt-wrapper").encrypt_buffer()')
    vim.api.nvim_command('command! Decrypt lua require("ccrypt-wrapper").decrypt_buffer()')
    vim.api.nvim_set_keymap("n", "<leader>ce", ":Encrypt<CR>", { noremap = true, silent = true })
    vim.api.nvim_set_keymap("n", "<leader>cd", ":Decrypt<CR>", { noremap = true, silent = true })
end

return M
