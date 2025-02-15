local ffi = require "ffi"

ffi.cdef [[
    typedef unsigned int UINT, HWND, WPARAM;
    typedef unsigned long LPARAM, LRESULT;
    LRESULT SendMessageA(HWND hWnd, UINT Msg, WPARAM wParam, LPARAM lParam);
    HWND ImmGetDefaultIMEWnd(HWND unnamedParam1);
    HWND GetForegroundWindow();
]]

local user32 = ffi.load "user32.dll"
local imm32 = ffi.load "imm32.dll"

local ime_hwnd
local ime_group = vim.api.nvim_create_augroup("ime_toggle", { clear = true })
local ime_states = {}  -- バッファごとのIME状態を保持するテーブル

local WM_IME_CONTROL = 0x283
local IMC_GETCONVERSIONMODE = 0x001
local IMC_SETCONVERSIONMODE = 0x002
local IMC_GETOPENSTATUS = 0x005
local IMC_SETOPENSTATUS = 0x006

local function get_ime_window()
    return imm32.ImmGetDefaultIMEWnd(user32.GetForegroundWindow())
end

local function get_ime_status()
    return user32.SendMessageA(ime_hwnd, WM_IME_CONTROL, IMC_GETOPENSTATUS, 0)
end

local function set_ime_status(status)
    return user32.SendMessageA(ime_hwnd, WM_IME_CONTROL, IMC_SETOPENSTATUS, status)
end

local function get_ime_mode()
    return user32.SendMessageA(ime_hwnd, WM_IME_CONTROL, IMC_GETCONVERSIONMODE, 0)
end

local function set_ime_mode(mode)
    return user32.SendMessageA(ime_hwnd, WM_IME_CONTROL, IMC_SETCONVERSIONMODE, mode)
end

-- InsertLeave/CmdlineLeaveのハンドラ
vim.api.nvim_create_autocmd({ "InsertLeave", "CmdlineLeave" }, {
    group = ime_group,
    callback = function()
        ime_hwnd = get_ime_window()
        if ime_hwnd then
            -- 現在の状態を保存
            local bufnr = vim.api.nvim_get_current_buf()
            ime_states[bufnr] = {
                status = get_ime_status(),
                mode = get_ime_mode()
            }
            -- IMEをオフにしてモードを0に
            set_ime_status(0)
            set_ime_mode(0)
        end
    end,
})

-- InsertEnter/CmdlineEnterのハンドラ
vim.api.nvim_create_autocmd({ "InsertEnter", "CmdlineEnter" }, {
    group = ime_group,
    callback = function()
        ime_hwnd = get_ime_window()
        if ime_hwnd then
            -- 保存されていた状態を復元（存在確認付き）
            local bufnr = vim.api.nvim_get_current_buf()
            local state = ime_states[bufnr]
            if state then
                set_ime_status(state.status)
                set_ime_mode(state.mode)
            end
        end
    end,
})

-- バッファが削除されたときのクリーンアップ
vim.api.nvim_create_autocmd("BufDelete", {
    group = ime_group,
    callback = function(args)
        ime_states[args.buf] = nil
    end,
})

return {}