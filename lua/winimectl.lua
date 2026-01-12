local M = {}

-- デフォルト設定
local default_config = {
  exe_path = nil, -- Path to ImeControl.exe (for WSL)
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

  -- バックエンド抽象化層の初期化
  local backend = require("winimectl.backend")
  if not backend.init({ exe_path = config.exe_path }) then
    vim.notify("[winimectl] Backend initialization failed", vim.log.levels.ERROR)
    return
  end

  local ime_group = vim.api.nvim_create_augroup("ime_toggle", { clear = true })
  local insert_states = {}  -- insertモードのIME状態
  local cmdline_states = {} -- コマンドラインのIME状態

  -- InsertLeaveのハンドラ
  if config.insert.enable then
    vim.api.nvim_create_autocmd("InsertLeave", {
      group = ime_group,
      callback = function()
        -- 現在の状態を保存
        local bufnr = vim.api.nvim_get_current_buf()
        insert_states[bufnr] = {
          status = backend.get_ime_status(),
          mode = backend.get_ime_mode()
        }
        -- 設定に従ってIMEの状態を変更
        if config.insert.on_leave.ime_off then
          backend.set_ime_status(0)
        end
        backend.set_ime_mode(config.insert.on_leave.set_mode)
      end,
    })

    -- InsertEnterのハンドラ（enableの時のみ）
    vim.api.nvim_create_autocmd("InsertEnter", {
      group = ime_group,
      callback = function()
        -- 保存されていた状態を復元
        local bufnr = vim.api.nvim_get_current_buf()
        local state = insert_states[bufnr]
        if state then
          backend.set_ime_status(state.status)
          backend.set_ime_mode(state.mode)
        end
      end,
    })
  end

  -- CmdlineLeaveのハンドラ
  if config.cmdline.enable then
    vim.api.nvim_create_autocmd("CmdlineLeave", {
      group = ime_group,
      callback = function()
        -- 現在の状態を保存
        local bufnr = vim.api.nvim_get_current_buf()
        cmdline_states[bufnr] = {
          status = backend.get_ime_status(),
          mode = backend.get_ime_mode()
        }
        -- 設定に従ってIMEの状態を変更
        if config.cmdline.on_leave.ime_off then
          backend.set_ime_status(0)
        end
        backend.set_ime_mode(config.cmdline.on_leave.set_mode)
      end,
    })

    -- CmdlineEnterのハンドラ（enableの時のみ）
    vim.api.nvim_create_autocmd("CmdlineEnter", {
      group = ime_group,
      callback = function()
        -- 保存されていた状態を復元
        local bufnr = vim.api.nvim_get_current_buf()
        local state = cmdline_states[bufnr]
        if state then
          backend.set_ime_status(state.status)
          backend.set_ime_mode(state.mode)
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
