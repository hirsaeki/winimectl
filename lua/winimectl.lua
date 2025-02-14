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
        function(status)
          if status ~= nil then
            -- 状態の保存に成功したら、IMEをオフにする
            vim.b.prev_ime_status = status
            vim.fn['denops#request'](
              'winimectl',
              'setImeStatus',
              {false},
              function(_)
                -- 成功時は何もしない
              end,
              function(err)
                vim.api.nvim_err_writeln("[winimectl] Failed to disable IME: " .. vim.inspect(err))
              end
            )
          end
        end,
        function(err)
          vim.api.nvim_err_writeln("[winimectl] Failed to get IME status: " .. vim.inspect(err))
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
        vim.fn['denops#request'](
          'winimectl',
          'setImeStatus',
          {prev_status},
          function(_)
            -- 成功時は何もしない
          end,
          function(err)
            vim.api.nvim_err_writeln("[winimectl] Failed to restore IME status: " .. vim.inspect(err))
          end
        )
      end
    end,
  })
end

return M