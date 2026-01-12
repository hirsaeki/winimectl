--- Backend abstraction layer module
--- Provides platform-agnostic interface to IME control backends
local M = {}

--- @type table|nil Currently selected backend
local backend = nil

--- @type boolean Whether backend is initialized
local initialized = false

--- Initialize the backend based on current platform
--- @return boolean success Whether initialization succeeded
function M.init()
  if initialized then
    return backend ~= nil
  end

  local util = require("winimectl.util")
  local platform = util.get_platform()

  if platform == "windows" then
    local ok, ffi_backend = pcall(require, "winimectl.backend.ffi")
    if ok then
      backend = ffi_backend
      initialized = true
      if backend.init then
        return backend.init()
      end
      return true
    else
      vim.notify("[winimectl] Failed to load FFI backend: " .. tostring(ffi_backend), vim.log.levels.ERROR)
      initialized = true
      return false
    end
  elseif platform == "wsl" then
    local ok, wsl_backend = pcall(require, "winimectl.backend.wsl")
    if ok then
      backend = wsl_backend
      initialized = true
      if backend.init then
        return backend.init()
      end
      return true
    else
      vim.notify("[winimectl] Failed to load WSL backend: " .. tostring(wsl_backend), vim.log.levels.ERROR)
      initialized = true
      return false
    end
  else
    vim.notify("[winimectl] Unsupported platform: " .. platform, vim.log.levels.WARN)
    initialized = true
    return false
  end
end

--- Check if a backend is available
--- @return boolean
function M.is_available()
  return backend ~= nil
end

--- Get IME status (on/off)
--- @return number status IME status (0=off, 1=on), or 0 if backend unavailable
function M.get_ime_status()
  if not backend then
    return 0
  end
  return backend.get_ime_status()
end

--- Set IME status (on/off)
--- @param status number IME status to set (0=off, 1=on)
--- @return number result Result of the operation, or 0 if backend unavailable
function M.set_ime_status(status)
  if not backend then
    return 0
  end
  return backend.set_ime_status(status)
end

--- Get IME conversion mode
--- @return number mode Current IME mode, or 0 if backend unavailable
function M.get_ime_mode()
  if not backend then
    return 0
  end
  return backend.get_ime_mode()
end

--- Set IME conversion mode
--- @param mode number IME mode to set
--- @return number result Result of the operation, or 0 if backend unavailable
function M.set_ime_mode(mode)
  if not backend then
    return 0
  end
  return backend.set_ime_mode(mode)
end

return M
