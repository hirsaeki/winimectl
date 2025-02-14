local M = {}

function M.setup(opts)
  opts = opts or {}

  -- Create autocommands for IME control
  local group = vim.api.nvim_create_augroup("WinImectl", { clear = true })

  -- InsertLeaveでのIME制御
  vim.api.nvim_create_autocmd("InsertLeave", {
    group = group,
    callback = function()
      -- まず現在のIMEの状態を取得
      vim.fn['denops#request'](
        'winimectl',
        'getImeStatus',
        {},
        function(err, status)
          if not err and status ~= nil then
            -- 状態の保存に成功したら、IMEをオフにする
            vim.b.prev_ime_status = status
            vim.fn['denops#request']('winimectl', 'setImeStatus', {false})
          end
        end
      )
    end,
  })

  -- InsertEnterでのIME制御
  vim.api.nvim_create_autocmd("InsertEnter", {
    group = group,
    callback = function()
      -- 保存されていた以前のIME状態を復元
      local prev_status = vim.b.prev_ime_status
      if prev_status ~= nil then
        vim.fn['denops#request']('winimectl', 'setImeStatus', {prev_status})
      end
    end,
  })
end

return M