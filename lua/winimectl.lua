-- winimectl.lua - Windows IME Control for Neovim
-- Reference:
-- https://www.cnblogs.com/yf-zhao/p/16018481.html
-- https://zhuanlan.zhihu.com/p/425951648

local M = {}

-- FFI definitions
local ffi = require "ffi"

ffi.cdef [[
    typedef void* HANDLE;
    typedef HANDLE HWND;
    typedef unsigned int UINT;
    typedef unsigned long DWORD;
    typedef DWORD WPARAM;
    typedef long LPARAM;
    typedef long LRESULT;
    typedef int BOOL;

    HWND GetForegroundWindow(void);
    HWND ImmGetDefaultIMEWnd(HWND);
    LRESULT SendMessageA(HWND, UINT, WPARAM, LPARAM);
    BOOL IsWindow(HWND);
    BOOL IsWindowEnabled(HWND);
]]

-- Load required DLLs
local user32 = ffi.load "user32.dll"
local imm32 = ffi.load "imm32.dll"

-- Constants
local WM_IME_CONTROL = 0x283
local IMC_GETCONVERSIONMODE = 0x001
local IMC_SETCONVERSIONMODE = 0x002

-- Default settings
local default_config = {
    debug = false,  -- デバッグメッセージを表示するか
    ime_mode = {
        jp = 1025,  -- 日本語入力モード
        en = 0,     -- 英語入力モード
    },
    retry = {
        count = 3,      -- リトライ回数
        interval = 100,  -- リトライ間隔（ミリ秒）
    },
}

local config = vim.deepcopy(default_config)
local ime_hwnd = nil
local ime_group = nil

-- Helper functions
local function debug_print(msg)
    if config.debug then
        vim.notify("[winimectl] " .. msg, vim.log.levels.DEBUG)
    end
end

local function error_print(msg)
    vim.notify("[winimectl] Error: " .. msg, vim.log.levels.ERROR)
end

local function is_valid_window(hwnd)
    if hwnd == nil or hwnd == 0 then
        return false
    end
    return user32.IsWindow(hwnd) ~= 0 and user32.IsWindowEnabled(hwnd) ~= 0
end

local function get_ime_window()
    local fg_hwnd = user32.GetForegroundWindow()
    if not is_valid_window(fg_hwnd) then
        error_print("Failed to get foreground window")
        return nil
    end
    debug_print(string.format("Foreground window handle: 0x%x", tonumber(fg_hwnd)))

    local ime_hwnd = imm32.ImmGetDefaultIMEWnd(fg_hwnd)
    if not is_valid_window(ime_hwnd) then
        error_print("Failed to get IME window")
        return nil
    end
    debug_print(string.format("IME window handle: 0x%x", tonumber(ime_hwnd)))

    return ime_hwnd
end

local function get_ime_mode()
    if ime_hwnd == nil then
        ime_hwnd = get_ime_window()
        if ime_hwnd == nil then return nil end
    end

    local mode = user32.SendMessageA(ime_hwnd, WM_IME_CONTROL, IMC_GETCONVERSIONMODE, 0)
    debug_print(string.format("Current IME mode: 0x%x", tonumber(mode)))
    return mode
end

local function set_ime_mode(mode)
    if ime_hwnd == nil then
        ime_hwnd = get_ime_window()
        if ime_hwnd == nil then return false end
    end

    local result = user32.SendMessageA(ime_hwnd, WM_IME_CONTROL, IMC_SETCONVERSIONMODE, mode)
    if result == 0 then
        error_print(string.format("Failed to set IME mode to 0x%x", tonumber(mode)))
        return false
    end
    debug_print(string.format("Set IME mode to 0x%x", tonumber(mode)))
    return true
end

-- Setup function
function M.setup(opts)
    -- マージ設定
    if opts then
        config = vim.tbl_deep_extend("force", default_config, opts)
    end

    -- 既存のグループをクリア
    if ime_group then
        vim.api.nvim_del_augroup_by_id(ime_group)
    end

    -- 新しいautocmdグループを作成
    ime_group = vim.api.nvim_create_augroup("WinImectl", { clear = true })

    -- IMEウィンドウ取得のための自動コマンド
    vim.api.nvim_create_autocmd({ "InsertEnter", "CmdlineEnter" }, {
        group = ime_group,
        desc = "Initialize IME window and restore previous mode",
        callback = function()
            ime_hwnd = get_ime_window()
            if ime_hwnd then
                debug_print("IME window handle initialized")
                -- 保存されていた以前のIME状態を復元
                local prev_mode = vim.b.prev_ime_mode
                if prev_mode then
                    debug_print(string.format("Restoring previous IME mode: 0x%x", tonumber(prev_mode)))
                    if not set_ime_mode(prev_mode) then
                        error_print("Failed to restore previous IME mode")
                    end
                end
            end
        end,
    })

    -- IMEモード制御の自動コマンド
    vim.api.nvim_create_autocmd({ "InsertLeave", "CmdlineLeave" }, {
        group = ime_group,
        desc = "Save current mode and set IME to English mode",
        callback = function()
            local current_mode = get_ime_mode()
            if current_mode then
                -- 現在のモードを保存
                vim.b.prev_ime_mode = current_mode
                debug_print(string.format("Saved current IME mode: 0x%x", tonumber(current_mode)))
                
                -- 英語モードに切り替え
                if current_mode == config.ime_mode.jp then
                    if not set_ime_mode(config.ime_mode.en) then
                        error_print("Failed to switch to English mode")
                    end
                end
            end
        end,
    })

    -- グローバル関数を追加（デバッグ用）
    _G.winimectl_get_mode = function()
        local mode = get_ime_mode()
        if mode then
            print(string.format("Current IME mode: 0x%x", tonumber(mode)))
        end
    end

    _G.winimectl_set_mode = function(mode)
        if set_ime_mode(mode) then
            print(string.format("Set IME mode to 0x%x", tonumber(mode)))
        end
    end

    debug_print("WinImectl initialized with config: " .. vim.inspect(config))
end

return M