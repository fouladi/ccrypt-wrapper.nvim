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

    -- Save buffer to file forcibly
    vim.api.nvim_command("write!")

    local original_path = vim.api.nvim_buf_get_name(0)
    if original_path == "" then
        print("Encryption aborted: Buffer has no name.")
        return
    end

    -- Check file content
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

    local cp_path = original_path .. ".cp"

    -- Create secure password file
    local passfile = vim.fn.tempname()
    local f = io.open(passfile, "w")
    if not f then
        print("Encryption aborted: Cannot write temp password file.")
        return
    end
    f:write(password1, "\n")
    f:close()
    os.execute("chmod 600 " .. passfile)

    -- Run ccrypt
    local cmd = string.format("ccrypt -e -k %s -o %s %s", passfile, cp_path, original_path)
    local handle = io.popen(cmd .. " 2>&1")
    local output = handle:read("*a")
    local ok, _, exitcode = handle:close()
    os.remove(passfile)

    if ok and vim.fn.filereadable(cp_path) == 1 then
        print("✅ Encrypted successfully to: " .. cp_path)
        vim.cmd("edit " .. cp_path)
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
