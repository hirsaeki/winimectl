-- WSL backend for winimectl
-- Uses ImeControl.exe to control Windows IME from WSL
local M = {}

-- Internal state
local initialized = false
local exe_path = nil

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
---@return string|nil Path to ImeControl.exe, or nil if not found
local function resolve_exe_path()
  -- Get the path to the plugin directory
  local runtime_files = vim.api.nvim_get_runtime_file("lua/winimectl.lua", false)
  if not runtime_files or #runtime_files == 0 then
    return nil
  end

  -- Get parent directory of lua/winimectl.lua (the plugin root)
  local plugin_lua_path = runtime_files[1]
  -- Go up from lua/winimectl.lua to plugin root
  local plugin_root = vim.fn.fnamemodify(plugin_lua_path, ":h:h")
  local win_exe_path = plugin_root .. "/wsl/ImeControl.exe"

  -- Check if the file exists (using Windows path for existence check)
  if vim.fn.filereadable(win_exe_path) ~= 1 then
    return nil
  end

  -- Convert to WSL path for execution
  return to_wsl_path(win_exe_path)
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
---@return boolean True if initialization succeeded
function M.init()
  if initialized then
    return true
  end

  exe_path = resolve_exe_path()
  if not exe_path then
    vim.notify(
      "[winimectl] ImeControl.exe not found. Please compile wsl/ImeControl.cs",
      vim.log.levels.ERROR
    )
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
