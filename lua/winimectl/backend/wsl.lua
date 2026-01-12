-- WSL backend for winimectl
-- Uses ImeControl.exe to control Windows IME from WSL
local M = {}

-- Internal state
local initialized = false
local exe_path = nil
local config_exe_path = nil  -- Path from user config

--- Convert Windows path to WSL path
--- D:\path\to\file -> /mnt/d/path/to/file
---@param win_path string Windows path
---@return string WSL path
local function to_wsl_path(win_path)
  -- Replace backslashes with forward slashes
  local path = win_path:gsub("\\", "/")
  -- Convert drive letter (e.g., D:/path -> /mnt/d/path)
  path = path:gsub("^(%a):/", function(drive)
    return "/mnt/" .. drive:lower() .. "/"
  end)
  return path
end

--- Resolve the path to ImeControl.exe
--- Searches in order: 1. PATH, 2. user config, 3. returns nil
---@return string|nil Path to ImeControl.exe, or nil if not found
local function resolve_exe_path()
  -- 1. First, try to find ImeControl.exe in PATH
  local path_exe = vim.fn.exepath("ImeControl.exe")
  if path_exe and path_exe ~= "" then
    -- exepath returns WSL-compatible path
    return path_exe
  end

  -- 2. If not in PATH, use the config-provided path
  if config_exe_path and config_exe_path ~= "" then
    -- Check if it's a Windows path (contains backslash or drive letter)
    local resolved_path = config_exe_path
    if config_exe_path:match("^%a:\\") or config_exe_path:match("\\") then
      resolved_path = to_wsl_path(config_exe_path)
    end
    -- Verify the file exists
    if vim.fn.filereadable(resolved_path) == 1 or vim.fn.executable(resolved_path) == 1 then
      return resolved_path
    end
  end

  -- 3. Not found
  return nil
end

--- Execute ImeControl.exe with given arguments
---@param ... string Command arguments
---@return string|nil Output from the command, or nil on error
local function execute_ime_control(...)
  if not initialized or not exe_path then
    return nil
  end

  local args = { exe_path, ... }
  local result = vim.fn.system(args)

  if vim.v.shell_error ~= 0 then
    return nil
  end

  return vim.trim(result)
end

--- Initialize the WSL backend
--- Checks for ImeControl.exe existence and sets up internal state
---@param opts table|nil Options table with optional exe_path field
---@return boolean True if initialization succeeded
function M.init(opts)
  if initialized then
    return true
  end

  -- Store config exe_path if provided
  if opts and opts.exe_path then
    config_exe_path = opts.exe_path
  end

  exe_path = resolve_exe_path()
  if not exe_path then
    local error_msg = [[
[winimectl] ImeControl.exe not found.

Setup instructions:
1. Copy ImeControl.exe to a directory in your Windows PATH
   (e.g., C:\Users\<username>\bin\)
2. Or specify the path in setup:
   require('winimectl').setup({
     exe_path = '/mnt/c/path/to/ImeControl.exe'
   })

To build ImeControl.exe:
  cd <plugin_dir>/wsl
  csc.exe /out:ImeControl.exe ImeControl.cs]]
    vim.notify(error_msg, vim.log.levels.ERROR)
    return false
  end

  initialized = true
  return true
end

--- Check if the backend is available (initialized)
---@return boolean True if the backend is ready to use
function M.is_available()
  return initialized
end

--- Get IME on/off status
---@return number IME status (0 = off, 1 = on), or 0 if not initialized
function M.get_ime_status()
  local result = execute_ime_control("get_status")
  if result then
    return tonumber(result) or 0
  end
  return 0
end

--- Set IME on/off status
---@param status number IME status to set (0 = off, 1 = on)
function M.set_ime_status(status)
  if not initialized then
    return
  end
  execute_ime_control("set_status", tostring(status))
end

--- Get IME conversion mode
---@return number Conversion mode value, or 0 if not initialized
function M.get_ime_mode()
  local result = execute_ime_control("get_mode")
  if result then
    return tonumber(result) or 0
  end
  return 0
end

--- Set IME conversion mode
---@param mode number Conversion mode value to set
function M.set_ime_mode(mode)
  if not initialized then
    return
  end
  execute_ime_control("set_mode", tostring(mode))
end

return M
