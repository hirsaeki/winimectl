--- FFI backend module for winimectl.nvim
--- Provides Windows IME control via LuaJIT FFI
local M = {}

local ffi = require("ffi")

-- Module state
local initialized = false
local user32 = nil
local imm32 = nil

-- Windows API constants
local WM_IME_CONTROL = 0x283
local IMC_GETCONVERSIONMODE = 0x001
local IMC_SETCONVERSIONMODE = 0x002
local IMC_GETOPENSTATUS = 0x005
local IMC_SETOPENSTATUS = 0x006

--- Initialize FFI bindings
--- @return boolean success
function M.init()
  if initialized then
    return true
  end

  -- Define C types and functions (wrap in pcall for duplicate definition safety)
  local ok, err = pcall(function()
    ffi.cdef([[
      typedef unsigned int UINT;
      typedef void* HWND;
      typedef unsigned long long WPARAM;
      typedef long long LPARAM;
      typedef long long LRESULT;
      LRESULT SendMessageA(HWND hWnd, UINT Msg, WPARAM wParam, LPARAM lParam);
      HWND ImmGetDefaultIMEWnd(HWND unnamedParam1);
      HWND GetForegroundWindow();
    ]])
  end)

  if not ok and not string.find(tostring(err), "redefin") then
    -- Real error (not just redefinition)
    return false
  end

  -- Load DLLs
  local load_ok, load_err = pcall(function()
    user32 = ffi.load("user32.dll")
    imm32 = ffi.load("imm32.dll")
  end)

  if not load_ok then
    return false
  end

  initialized = true
  return true
end

--- Check if the backend is available and initialized
--- @return boolean
function M.is_available()
  return initialized
end

--- Get the IME window handle for the foreground window
--- @return ffi.cdata|nil IME window handle or nil if not available
local function get_ime_window()
  if not initialized then
    return nil
  end
  local hwnd = user32.GetForegroundWindow()
  if hwnd == nil then
    return nil
  end
  return imm32.ImmGetDefaultIMEWnd(hwnd)
end

--- Get IME on/off status
--- @return number status (0 = off, non-zero = on)
function M.get_ime_status()
  local ime_hwnd = get_ime_window()
  if ime_hwnd == nil then
    return 0
  end
  local result = user32.SendMessageA(ime_hwnd, WM_IME_CONTROL, IMC_GETOPENSTATUS, 0)
  return tonumber(result) or 0
end

--- Set IME on/off status
--- @param status number (0 = off, 1 = on)
--- @return number result
function M.set_ime_status(status)
  local ime_hwnd = get_ime_window()
  if ime_hwnd == nil then
    return 0
  end
  local result = user32.SendMessageA(ime_hwnd, WM_IME_CONTROL, IMC_SETOPENSTATUS, status)
  return tonumber(result) or 0
end

--- Get IME conversion mode
--- @return number mode
function M.get_ime_mode()
  local ime_hwnd = get_ime_window()
  if ime_hwnd == nil then
    return 0
  end
  local result = user32.SendMessageA(ime_hwnd, WM_IME_CONTROL, IMC_GETCONVERSIONMODE, 0)
  return tonumber(result) or 0
end

--- Set IME conversion mode
--- @param mode number
--- @return number result
function M.set_ime_mode(mode)
  local ime_hwnd = get_ime_window()
  if ime_hwnd == nil then
    return 0
  end
  local result = user32.SendMessageA(ime_hwnd, WM_IME_CONTROL, IMC_SETCONVERSIONMODE, mode)
  return tonumber(result) or 0
end

return M
