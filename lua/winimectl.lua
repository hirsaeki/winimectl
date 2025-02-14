local M = {}

function M.setup(opts)
  opts = opts or {}

  -- Create autocommands for IME control
  local group = vim.api.nvim_create_augroup("WinImectl", { clear = true })

  vim.api.nvim_create_autocmd("InsertLeave", {
    group = group,
    callback = function()
      vim.fn['denops#request_async'](
        'winimectl',
        'getImeStatus',
        {},
        function(err, status)
          if not err and status ~= nil then
            vim.b.prev_ime_status = status
            vim.fn['denops#notify']('winimectl', 'setImeStatus', {false})
          else
            vim.api.nvim_err_writeln("Failed to get IME status: " .. (err or "unknown error"))
          end
        end,
        function(err)
          vim.api.nvim_err_writeln("Error in denops request: " .. vim.inspect(err))
        end
      )
    end,
  })

  vim.api.nvim_create_autocmd("InsertEnter", {
    group = group,
    callback = function()
      -- Restore previous IME status
      local prev_status = vim.b.prev_ime_status
      if prev_status ~= nil then
        vim.fn['denops#notify']('winimectl', 'setImeStatus', {prev_status})
      end
    end,
  })
end

return M