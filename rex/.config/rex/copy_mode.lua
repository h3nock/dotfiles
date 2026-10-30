-- An isolated, read-only viewer. No user plugins, ShaDa, swap, or undo files.
vim.opt.loadplugins = false
vim.opt.shadafile = "NONE"
vim.opt.swapfile = false
vim.opt.undofile = false
vim.opt.backup = false
vim.opt.writebackup = false
vim.opt.modeline = false
vim.opt.clipboard = ""
vim.opt.wrap = false
vim.opt.number = false
vim.opt.relativenumber = false
vim.opt.signcolumn = "no"
vim.opt.laststatus = 2
vim.opt.showmode = true
vim.opt.incsearch = true
vim.opt.hlsearch = true
vim.opt.ignorecase = true
vim.opt.smartcase = true
vim.opt.mouse = "a"
vim.opt.statusline = " Vim Copy · snapshot  %=%l/%L  v/V/Ctrl-V select · y/Enter copy · q exit "

local function close()
  vim.cmd("qa!")
end

vim.keymap.set("n", "q", close)
vim.keymap.set("n", "<Esc>", close)
vim.keymap.set("x", "<CR>", "y")
vim.keymap.set("n", "<CR>", "yy")

vim.api.nvim_create_autocmd("VimEnter", {
  once = true,
  callback = function()
    vim.bo.buftype = "nofile"
    vim.bo.bufhidden = "wipe"
    vim.bo.modifiable = false
    vim.cmd("normal! G$zb")
  end,
})

vim.api.nvim_create_autocmd("TextYankPost", {
  callback = function()
    local event = vim.v.event
    if event.operator ~= "y" then
      return
    end
    local lines = vim.deepcopy(event.regcontents)
    if event.regtype == "V" then
      lines[#lines + 1] = "" -- Preserve the final newline of a linewise yank.
    end
    -- Send the clipboard to the Rex client displaying this terminal. Calling
    -- pbcopy here would instead change the server machine's clipboard.
    require("vim.ui.clipboard.osc52").copy("+")(lines)
    vim.schedule(close)
  end,
})
