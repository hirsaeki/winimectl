local M = {}

function M.setup(opts)
  opts = opts or {}

  -- Create autocommands for IME control
  local group = vim.api.nvim_create_augroup("WinImectl", { clear = true })

  vim.api.nvim_create_autocmd("InsertLeave", {
    group = group,
    callback = function()
      -- Store current IME status before disabling
      vim.fn['denops#request']('winimectl', 'getImeStatus', {}, function(err, status)
        if not err then
          vim.b.prev_ime_status = status
          -- Disable IME
          vim.fn['denops#notify']('winimectl', 'setImeStatus', {false})
        end
      end)
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