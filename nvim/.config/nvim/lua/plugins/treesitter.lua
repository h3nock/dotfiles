-- nvim-treesitter's main branch needs Neovim 0.12+ and tree-sitter-cli (in the
-- Brewfile). It installs parsers but no longer starts highlighting or
-- indenting, so the FileType autocmd below does that.
return {
  {
    "nvim-treesitter/nvim-treesitter",
    branch = "main",
    lazy = false,
    build = ":TSUpdate",
    opts = {
      ensure_installed = {
        "lua",
        "json",
        "python",
        "cpp",
        "typescript",
        "markdown",
        "markdown_inline",
        "latex",
        "tsx",
      },
      install_dir = vim.fn.stdpath "data" .. "/site",
    },
    config = function(_, opts)
      pcall(function()
        dofile(vim.g.base46_cache .. "syntax")
        dofile(vim.g.base46_cache .. "treesitter")
      end)

      local treesitter = require "nvim-treesitter"

      treesitter.setup {
        install_dir = opts.install_dir,
      }
      -- Installs the parsers that are missing, in the background; once they
      -- are all installed this does nothing.
      treesitter.install(opts.ensure_installed)

      local indent_disabled = {
        python = true,
        cpp = true,
      }

      vim.api.nvim_create_autocmd("FileType", {
        group = vim.api.nvim_create_augroup("UserTreesitter", { clear = true }),
        callback = function(args)
          -- Without a parser, keep Vim's own indent rules for the filetype.
          if not pcall(vim.treesitter.start, args.buf) then
            return
          end
          if not indent_disabled[vim.bo[args.buf].filetype] then
            vim.bo[args.buf].indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
          end
        end,
      })
    end,
  },
}
