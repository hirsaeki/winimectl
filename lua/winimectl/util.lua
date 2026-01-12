--- WSL environment detection utility module
local M = {}

--- Check if running in WSL environment
--- @return boolean
function M.is_wsl()
  -- Check WSL_DISTRO_NAME environment variable
  if vim.env.WSL_DISTRO_NAME then
    return true
  end

  -- Check /proc/version for WSL indicators
  local proc_version = vim.fn.filereadable("/proc/version") == 1
  if proc_version then
    local content = vim.fn.readfile("/proc/version")[1] or ""
    content = content:lower()
    if content:find("microsoft") or content:find("wsl") then
      return true
    end
  end

  -- Check WSLInterop existence
  if vim.fn.filereadable("/proc/sys/fs/binfmt_misc/WSLInterop") == 1 then
    return true
  end

  return false
end

--- Get current platform
--- @return string "windows" | "wsl" | "unsupported"
function M.get_platform()
  if jit and jit.os == "Windows" then
    return "windows"
  end

  if M.is_wsl() then
    return "wsl"
  end

  return "unsupported"
end

return M
