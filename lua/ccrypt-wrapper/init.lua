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

    local password1 = vim.fn.inputsecret("Enter encryption password: ")
    local password2 = vim.fn.inputsecret("Repeat encryption password: ")

    if password1 == "" or password2 == "" then
        print("Encryption aborted: Empty password.")
        return
    end

    if password1 ~= password2 then
        print("Encryption aborted: Passwords do not match.")
        return
    end

    vim.cmd("write!")

    local original_path = vim.api.nvim_buf_get_name(0)
    if original_path == "" then
        print("Encryption aborted: Buffer has no name.")
        return
    end

    local encrypted_path = original_path .. ".cpt"

    -- Ask if .cpt file already exists
    if vim.fn.filereadable(encrypted_path) == 1 then
        local answer = vim.fn.input("File '" .. encrypted_path .. "' already exists. Overwrite? (y/N): ")
        if answer:lower() ~= "y" then
            print("Encryption cancelled by user.")
            return
        end
        os.remove(encrypted_path) -- remove before encrypting
    end

    -- Ensure file has content
    local fcheck = io.open(original_path, "rb")
    if not fcheck then
        print("Encryption aborted: Cannot open file '" .. original_path .. "'.")
        return
    end
    local content = fcheck:read("*a")
    fcheck:close()

    if not content or content == "" then
        print("Encryption aborted: File is empty.")
        return
    end

    -- Create password file
    local passfile = vim.fn.tempname()
    local f = io.open(passfile, "w")
    if not f then
        print("Encryption aborted: Cannot create temp password file.")
        return
    end
    f:write(password1, "\n")
    f:close()
    os.execute("chmod 600 " .. passfile)

    -- Encrypt using ccrypt
    local encrypt_cmd =
        string.format("ccrypt -e -k %s %s", vim.fn.shellescape(passfile), vim.fn.shellescape(original_path))
    local handle = io.popen(encrypt_cmd .. " 2>&1")
    local output = handle:read("*a")
    local ok, _, exitcode = handle:close()
    os.remove(passfile)

    if ok and vim.fn.filereadable(encrypted_path) == 1 then
        os.remove(original_path) -- 🔥 Delete source after success
        print("✅ Encrypted successfully to: " .. encrypted_path)
        vim.cmd("edit " .. encrypted_path)
    else
        print("❌ Encryption failed. Exit code: " .. tostring(exitcode))
        print("Output:\n" .. output)
    end
end

-- Function to decrypt buffer content using "ccrypt" with a password
M.decrypt_buffer = function()
    if not is_ccrypt_installed() then
        print("Error: ccrypt is not installed.")
        return
    end

    local password = vim.fn.inputsecret("Enter decryption password: ")
    if password == "" then
        print("Decryption aborted: Empty password.")
        return
    end

    vim.cmd("write!")

    local encrypted_path = vim.api.nvim_buf_get_name(0)
    if encrypted_path == "" or not encrypted_path:match("%.cpt$") then
        print("Decryption aborted: File is not a .cpt encrypted file.")
        return
    end

    local passfile = vim.fn.tempname()
    local f = io.open(passfile, "w")
    if not f then
        print("Decryption aborted: Cannot create temp password file.")
        return
    end
    f:write(password, "\n")
    f:close()
    os.execute("chmod 600 " .. passfile)

    -- Decrypt in-place (ccrypt will remove .cpt)
    local decrypt_cmd =
        string.format("ccrypt -d -k %s %s", vim.fn.shellescape(passfile), vim.fn.shellescape(encrypted_path))
    local handle = io.popen(decrypt_cmd .. " 2>&1")
    local output = handle:read("*a")
    local ok, _, exitcode = handle:close()
    os.remove(passfile)

    local decrypted_file = encrypted_path:gsub("%.cpt$", "")
    if ok and vim.fn.filereadable(decrypted_file) == 1 then
        print("✅ Decrypted successfully: " .. decrypted_file)
        vim.cmd("edit " .. decrypted_file)
    else
        print("❌ Decryption failed. Exit code: " .. tostring(exitcode))
        print("Output:\n" .. output)
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
