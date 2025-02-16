local M = {}

-- デフォルト設定
local default_config = {
  insert = {
    enable = true,    -- 有効にするかどうか。falseにするとInsertLeaveのハンドラが登録されない
    on_leave = {
      ime_off = true, -- IMEをオフにする。falseにするとIMEのオンオフ状態は変更されない
      set_mode = 0,   -- モード0にする
    }
  },
  cmdline = {
    enable = true,    -- 有効にするかどうか。falseにするとCmdlineLeaveのハンドラが登録されない
    on_leave = {
      ime_off = true, -- IMEをオフにする
      set_mode = 0,   -- モード0にする
    }
  }
}

function M.setup(opts)
  -- 設定のマージ
  local config = vim.tbl_deep_extend("force", default_config, opts or {})

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
  local insert_states = {}  -- insertモードのIME状態
  local cmdline_states = {} -- コマンドラインのIME状態

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

  -- InsertLeaveのハンドラ
  if config.insert.enable then
    vim.api.nvim_create_autocmd("InsertLeave", {
      group = ime_group,
      callback = function()
        ime_hwnd = get_ime_window()
        if ime_hwnd then
          -- 現在の状態を保存
          local bufnr = vim.api.nvim_get_current_buf()
          insert_states[bufnr] = {
            status = get_ime_status(),
            mode = get_ime_mode()
          }
          -- 設定に従ってIMEの状態を変更
          if config.insert.on_leave.ime_off then
            set_ime_status(0)
          end
          set_ime_mode(config.insert.on_leave.set_mode)
        end
      end,
    })

    -- InsertEnterのハンドラ（enableの時のみ）
    vim.api.nvim_create_autocmd("InsertEnter", {
      group = ime_group,
      callback = function()
        ime_hwnd = get_ime_window()
        if ime_hwnd then
          -- 保存されていた状態を復元
          local bufnr = vim.api.nvim_get_current_buf()
          local state = insert_states[bufnr]
          if state then
            set_ime_status(state.status)
            set_ime_mode(state.mode)
          end
        end
      end,
    })
  end

  -- CmdlineLeaveのハンドラ
  if config.cmdline.enable then
    vim.api.nvim_create_autocmd("CmdlineLeave", {
      group = ime_group,
      callback = function()
        ime_hwnd = get_ime_window()
        if ime_hwnd then
          -- 現在の状態を保存
          local bufnr = vim.api.nvim_get_current_buf()
          cmdline_states[bufnr] = {
            status = get_ime_status(),
            mode = get_ime_mode()
          }
          -- 設定に従ってIMEの状態を変更
          if config.cmdline.on_leave.ime_off then
            set_ime_status(0)
          end
          set_ime_mode(config.cmdline.on_leave.set_mode)
        end
      end,
    })

    -- CmdlineEnterのハンドラ（enableの時のみ）
    vim.api.nvim_create_autocmd("CmdlineEnter", {
      group = ime_group,
      callback = function()
        ime_hwnd = get_ime_window()
        if ime_hwnd then
          -- 保存されていた状態を復元
          local bufnr = vim.api.nvim_get_current_buf()
          local state = cmdline_states[bufnr]
          if state then
            set_ime_status(state.status)
            set_ime_mode(state.mode)
          end
        end
      end,
    })
  end

  -- バッファが削除されたときのクリーンアップ
  vim.api.nvim_create_autocmd("BufDelete", {
    group = ime_group,
    callback = function(args)
      insert_states[args.buf] = nil
      cmdline_states[args.buf] = nil
    end,
  })
end

return M