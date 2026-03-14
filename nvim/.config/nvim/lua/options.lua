require "nvchad.options"

local opt = vim.opt

vim.filetype.add({
  extension = {
    mdx = "mdx",
  },
})

vim.api.nvim_create_autocmd("FileType", {
  pattern = { "markdown", "mdx", "markdown.jsx" },
  callback = function()
    vim.opt_local.wrap = true
    vim.opt_local.spell = true
    vim.opt_local.conceallevel = 2
    vim.opt_local.concealcursor = "nc"
    vim.treesitter.language.register("markdown", "mdx")
  end,
})

vim.api.nvim_create_autocmd("FileType", {
  pattern = { "rust" },
  callback = function()
    vim.opt_local.colorcolumn = "100"
  end,
})

vim.api.nvim_create_autocmd("FileType", {
  pattern = { "python" },
  callback = function()
    vim.opt_local.colorcolumn = "88"
  end,
})

vim.api.nvim_create_autocmd("FileType", {
  pattern = { "lua" },
  callback = function()
    vim.opt_local.colorcolumn = "120"
  end,
})

-- show relative line numbers
opt.relativenumber = true

-- set the color column at 80 chars
opt.colorcolumn = "80"

-- enable filetype indent scripts
vim.cmd [[filetype plugin indent on]]

-- spaces instead of tabs (optional, but consistent)
vim.opt.expandtab = true
vim.opt.shiftwidth = 4
vim.opt.tabstop = 4
vim.opt.softtabstop = 4
vim.opt.smarttab = true

-- auto-indent
opt.autoindent = true
opt.smartindent = true

-- for c-style blocks
-- opt.cindent = true
-- local o = vim.o
-- o.cursorlineopt ='both' -- to enable cursorline!
