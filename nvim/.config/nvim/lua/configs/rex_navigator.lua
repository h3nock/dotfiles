local M = {}

-- Use Vim windows first, then cross a Rex pane boundary at the edge.
function M.navigate(vim_direction, rex_direction)
  local previous = vim.api.nvim_get_current_win()
  vim.cmd.wincmd(vim_direction)
  if vim.api.nvim_get_current_win() ~= previous then
    return
  end

  if vim.fn.executable("rex") ~= 1 then
    vim.notify("Rex navigation: rex is not on PATH", vim.log.levels.WARN)
    return
  end

  vim.system({
    "rex",
    "--autostart=false",
    "--timeout", "3s",
    "-S", vim.env.REX_SERVER,
    "api", "call",
    "-s", vim.env.REX_SESSION,
    "session.focus_direction",
    vim.json.encode { direction = rex_direction, wrap = true },
  }, { text = true, timeout = 4000 }, function(result)
    if result.code ~= 0 then
      vim.schedule(function()
        vim.notify("Rex navigation: " .. vim.trim(result.stderr or "request failed"), vim.log.levels.WARN)
      end)
    end
  end)
end

return M
