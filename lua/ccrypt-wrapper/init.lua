local M = {}

-- Name of the environment variable used to hand the key to ccrypt (`ccrypt -E`).
-- This keeps the password off the command line (visible in `ps`) and off disk.
local KEY_ENV = "CCRYPT_WRAPPER_KEY"

local function notify(msg, level)
    vim.notify("ccrypt-wrapper: " .. msg, level or vim.log.levels.INFO)
end

local function err(msg)
    notify(msg, vim.log.levels.ERROR)
end

local function check_requirements()
    if vim.fn.has("nvim-0.10") == 0 then
        err("Neovim 0.10 or newer is required.")
        return false
    end
    if vim.fn.executable("ccrypt") == 0 then
        err("ccrypt is not installed.")
        return false
    end
    return true
end

-- Prompt for a password. Returns nil if aborted (empty input, <Esc> or <C-c>).
local function ask_password(prompt)
    local ok, password = pcall(vim.fn.inputsecret, prompt)
    if not ok or password == nil or password == "" then
        return nil
    end
    return password
end

-- Prompt for a password twice. Returns nil if aborted or the entries differ.
local function ask_new_password()
    local password = ask_password("Enter encryption password: ")
    if not password then
        err("Encryption aborted: No password provided.")
        return nil
    end
    local repeated = ask_password("Repeat encryption password: ")
    if password ~= repeated then
        err("Encryption aborted: Passwords do not match.")
        return nil
    end
    return password
end

-- Run ccrypt with the key passed via environment variable.
-- Returns the vim.SystemCompleted result ({ code, stdout, stderr }).
local function run_ccrypt(args, password, stdin)
    -- Options must come before any "--" in args.
    local cmd = { "ccrypt", "-E", KEY_ENV }
    vim.list_extend(cmd, args)
    return vim.system(cmd, {
        env = { [KEY_ENV] = password },
        stdin = stdin or false,
        text = false,
    }):wait()
end

local function ccrypt_error(result)
    local msg = vim.trim(result.stderr or "")
    if msg == "" then
        msg = "exit code " .. tostring(result.code)
    end
    return msg
end

-- Return the buffer content as the bytes that would be written to disk.
local function get_buffer_bytes(buf)
    local bo = vim.bo[buf]
    local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
    if #lines == 1 and lines[1] == "" then
        return ""
    end

    local sep = "\n"
    if not bo.binary then
        sep = ({ unix = "\n", dos = "\r\n", mac = "\r" })[bo.fileformat] or "\n"
    end

    local data = table.concat(lines, sep)
    -- Only 'eol' reflects the original bytes; 'fixeol' would append a byte
    -- that is not part of the file and corrupt ciphertext.
    if bo.eol then
        data = data .. sep
    end

    -- Undo the encoding conversion done when the file was read (e.g. latin1).
    local fenc = bo.fileencoding
    if not bo.binary and fenc ~= "" and fenc ~= "utf-8" then
        data = vim.iconv(data, "utf-8", fenc) or data
    end
    return data
end

-- Replace the buffer content with raw bytes.
-- binary = true is used for ciphertext so that writing the buffer reproduces
-- the exact bytes (no fileformat/encoding conversion, no added newline).
local function set_buffer_bytes(buf, data, binary, clear_undo)
    local bo = vim.bo[buf]
    local lines = vim.split(data, "\n", { plain = true })
    local eol = false
    if #lines > 1 and lines[#lines] == "" then
        table.remove(lines)
        eol = true
    end

    local ff = "unix"
    if not binary and #lines > 0 then
        local all_crlf = true
        for _, line in ipairs(lines) do
            if line:sub(-1) ~= "\r" then
                all_crlf = false
                break
            end
        end
        if all_crlf then
            ff = "dos"
            for i, line in ipairs(lines) do
                lines[i] = line:sub(1, -2)
            end
        end
    end

    local undolevels = bo.undolevels
    if clear_undo then
        -- Drop undo history so the plaintext cannot be recovered with `u`
        -- (or end up in an 'undofile').
        bo.undolevels = -1
    end
    vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
    if clear_undo then
        bo.undolevels = undolevels
    end

    bo.binary = binary
    bo.fileencoding = ""
    bo.eol = eol
    if binary then
        bo.fixeol = false
    else
        bo.fileformat = ff
    end
end

-- Encrypt the content of the current buffer in place.
M.encrypt_buffer = function()
    if not check_requirements() then
        return
    end
    local buf = vim.api.nvim_get_current_buf()
    if not vim.bo[buf].modifiable then
        err("Encryption aborted: Buffer is not modifiable.")
        return
    end

    local data = get_buffer_bytes(buf)
    if data == "" then
        err("Encryption aborted: Buffer is empty.")
        return
    end

    local password = ask_new_password()
    if not password then
        return
    end

    local result = run_ccrypt({ "-e" }, password, data)
    if result.code ~= 0 or not result.stdout or result.stdout == "" then
        err("Encryption failed: " .. ccrypt_error(result))
        return
    end

    set_buffer_bytes(buf, result.stdout, true, true)
    notify("Buffer encrypted. Write it to save the encrypted content.")
end

-- Decrypt the content of the current buffer in place.
M.decrypt_buffer = function()
    if not check_requirements() then
        return
    end
    local buf = vim.api.nvim_get_current_buf()
    if not vim.bo[buf].modifiable then
        err("Decryption aborted: Buffer is not modifiable.")
        return
    end

    local data = get_buffer_bytes(buf)
    if data == "" then
        err("Decryption aborted: Buffer is empty.")
        return
    end

    local password = ask_password("Enter decryption password: ")
    if not password then
        err("Decryption aborted: No password provided.")
        return
    end

    local result = run_ccrypt({ "-d" }, password, data)
    if result.code ~= 0 then
        err("Decryption failed: " .. ccrypt_error(result))
        return
    end

    set_buffer_bytes(buf, result.stdout or "", false, false)
    notify("Buffer decrypted.")
end

-- Open `path` in the current window and wipe the previous buffer, so that no
-- stale copy (e.g. the plaintext after encrypting) stays in memory.
local function replace_buffer(old_buf, path, binary)
    vim.cmd("edit " .. (binary and "++bin " or "") .. vim.fn.fnameescape(path))
    if vim.api.nvim_buf_is_valid(old_buf) and old_buf ~= vim.api.nvim_get_current_buf() then
        pcall(vim.api.nvim_buf_delete, old_buf, { force = true })
    end
end

local function confirm_overwrite(path)
    if vim.uv.fs_stat(path) == nil then
        return true
    end
    return vim.fn.confirm("File '" .. path .. "' already exists. Overwrite?", "&Yes\n&No", 2) == 1
end

-- Encrypt the file of the current buffer to `<file>.cpt` and open it.
M.encrypt_file = function()
    if not check_requirements() then
        return
    end
    local buf = vim.api.nvim_get_current_buf()
    if vim.bo[buf].buftype ~= "" then
        err("Encryption aborted: Buffer is not a regular file.")
        return
    end

    local original_path = vim.api.nvim_buf_get_name(buf)
    if original_path == "" then
        err("Encryption aborted: Buffer has no name.")
        return
    end
    if original_path:match("%.cpt$") then
        err("Encryption aborted: File already has a .cpt extension.")
        return
    end

    local password = ask_new_password()
    if not password then
        return
    end

    -- Make sure the file on disk matches the buffer.
    vim.cmd("silent update")

    local stat = vim.uv.fs_stat(original_path)
    if not stat or stat.type ~= "file" then
        err("Encryption aborted: Cannot read file '" .. original_path .. "'.")
        return
    end
    if stat.size == 0 then
        err("Encryption aborted: File is empty.")
        return
    end

    local encrypted_path = original_path .. ".cpt"
    if not confirm_overwrite(encrypted_path) then
        notify("Encryption cancelled by user.")
        return
    end

    -- ccrypt overwrites the file in place and renames it to <file>.cpt,
    -- so no unencrypted copy is left behind. -f: we already confirmed.
    local result = run_ccrypt({ "-e", "-f", "--", original_path }, password)
    if result.code ~= 0 or vim.uv.fs_stat(encrypted_path) == nil then
        err("Encryption failed: " .. ccrypt_error(result))
        return
    end

    replace_buffer(buf, encrypted_path, true)
    notify("Encrypted successfully to: " .. encrypted_path)
end

-- Decrypt the current `.cpt` file on disk and open the decrypted file.
M.decrypt_file = function()
    if not check_requirements() then
        return
    end
    local buf = vim.api.nvim_get_current_buf()
    local encrypted_path = vim.api.nvim_buf_get_name(buf)
    if vim.bo[buf].buftype ~= "" or not encrypted_path:match("%.cpt$") then
        err("Decryption aborted: File is not a .cpt encrypted file.")
        return
    end
    if vim.bo[buf].modified then
        -- Writing a text-mode buffer of ciphertext could corrupt the file.
        err("Decryption aborted: Buffer has unsaved changes. Save it or reload it with :e! first.")
        return
    end
    if vim.uv.fs_stat(encrypted_path) == nil then
        err("Decryption aborted: File '" .. encrypted_path .. "' does not exist.")
        return
    end

    local decrypted_path = encrypted_path:gsub("%.cpt$", "")
    if not confirm_overwrite(decrypted_path) then
        notify("Decryption cancelled by user.")
        return
    end

    local password = ask_password("Enter decryption password: ")
    if not password then
        err("Decryption aborted: No password provided.")
        return
    end

    -- ccrypt decrypts in place and removes the .cpt extension.
    local result = run_ccrypt({ "-d", "-f", "--", encrypted_path }, password)
    if result.code ~= 0 or vim.uv.fs_stat(decrypted_path) == nil then
        err("Decryption failed: " .. ccrypt_error(result))
        return
    end

    replace_buffer(buf, decrypted_path, false)
    notify("Decrypted successfully: " .. decrypted_path)
end

-- Setup function to define the user commands.
M.setup = function(_)
    local cmd = vim.api.nvim_create_user_command
    cmd("Encrypt", M.encrypt_buffer, { desc = "Encrypt the buffer content with ccrypt" })
    cmd("Decrypt", M.decrypt_buffer, { desc = "Decrypt the buffer content with ccrypt" })
    cmd("EncryptFile", M.encrypt_file, { desc = "Encrypt the current file to <file>.cpt with ccrypt" })
    cmd("DecryptFile", M.decrypt_file, { desc = "Decrypt the current .cpt file with ccrypt" })
end

return M
