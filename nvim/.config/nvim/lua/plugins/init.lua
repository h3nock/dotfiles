-- ~/.config/nvim/lua/plugins/init.lua
local plugins = {
  {
    "neovim/nvim-lspconfig",
    event = { "BufReadPre", "BufNewFile" },
    config = function()
      require("nvchad.configs.lspconfig").defaults()
      require "configs.lspconfig"
    end,
  },
  -- rustaceanvim
  {
    "mrcjkb/rustaceanvim",
    version = "^6", -- Recommended
    lazy = false, -- This plugin is already lazy
    init = function()
      local nvlsp = require "nvchad.configs.lspconfig"
      vim.g.rustaceanvim = {
        server = {
          on_attach = nvlsp.on_attach,
          capabilities = nvlsp.capabilities,
          settings = {
            ["rust-analyzer"] = {
              check = { command = "clippy" },
              completion = { addCallParentheses = true },
            },
          },
        },
      }
    end,
  },
  -- Mason for LSP server management
  {
    "williamboman/mason.nvim",
    config = function()
      require("mason").setup {
        PATH = "append",
      }
    end,
  },
  {
    "williamboman/mason-lspconfig.nvim",
    dependencies = { "mason.nvim" },
    config = function()
      require("mason-lspconfig").setup {
        ensure_installed = { "pyright", "tsserver", "gopls", "rust_analyzer", "jsonls", "yamlls", "clangd", "lua_ls" },
        automatic_installation = true,
      }
    end,
  },
  {
    "WhoIsSethDaniel/mason-tool-installer.nvim",
    dependencies = { "williamboman/mason.nvim" },
    opts = {
      ensure_installed = {
        -- match your conform formatters
        "black",
        "isort",
        "clang-format",
        "prettier", -- or "prettierd"
        "stylua",
        "gofumpt",
        "goimports",
        "golines",
        -- LSPs are optional here, but harmless if you want them managed too:
        -- "pyright", "gopls", "rust-analyzer", "clangd", "lua-language-server", "json-lsp", "yaml-language-server",
      },
      run_on_start = true,
      auto_update = true,
    },
  },
  -- Enhanced completion with rich documentation
  {
    "hrsh7th/nvim-cmp",
    event = "InsertEnter",
    dependencies = {
      "hrsh7th/cmp-nvim-lsp",
      "hrsh7th/cmp-buffer",
      "L3MON4D3/LuaSnip",
      "saadparwaiz1/cmp_luasnip",
      "rafamadriz/friendly-snippets",
      "onsails/lspkind.nvim",
    },
    config = function()
      local cmp = require "cmp"
      local luasnip = require "luasnip"
      local lspkind = require "lspkind"

      -- Load snippets
      require("luasnip.loaders.from_vscode").lazy_load()

      cmp.setup {
        snippet = {
          expand = function(args)
            luasnip.lsp_expand(args.body)
          end,
        },
        window = {
          completion = cmp.config.window.bordered(),
          documentation = cmp.config.window.bordered(),
        },
        mapping = cmp.mapping.preset.insert {
          ["<C-b>"] = cmp.mapping.scroll_docs(-4),
          ["<C-f>"] = cmp.mapping.scroll_docs(4),
          ["<C-Space>"] = cmp.mapping.complete(),
          ["<C-e>"] = cmp.mapping.abort(),
          ["<CR>"] = cmp.mapping.confirm { select = true },
          ["<Tab>"] = cmp.mapping(function(fallback)
            if cmp.visible() then
              cmp.select_next_item()
            elseif luasnip.expand_or_jumpable() then
              luasnip.expand_or_jump()
            else
              fallback()
            end
          end, { "i", "s" }),
          ["<S-Tab>"] = cmp.mapping(function(fallback)
            if cmp.visible() then
              cmp.select_prev_item()
            elseif luasnip.jumpable(-1) then
              luasnip.jump(-1)
            else
              fallback()
            end
          end, { "i", "s" }),
        },
        sources = cmp.config.sources {
          { name = "nvim_lsp", priority = 1000 },
          { name = "luasnip", priority = 750 },
          { name = "buffer", priority = 500 },
        },
        formatting = {
          format = lspkind.cmp_format {
            mode = "symbol_text",
            maxwidth = 60,
            ellipsis_char = "...",
            show_labelDetails = true, -- This shows function signatures
            before = function(entry, vim_item)
              -- Enhanced display of function details
              if entry.completion_item.detail then
                vim_item.menu = entry.completion_item.detail
              end
              return vim_item
            end,
          },
        },
        completion = {
          completeopt = "menu,menuone,noinsert",
        },
        experimental = {
          ghost_text = true,
        },
      }
    end,
  },

  -- Auto pairs
  {
    "windwp/nvim-autopairs",
    event = "InsertEnter",
    config = function()
      local autopairs = require "nvim-autopairs"
      autopairs.setup()

      -- CMP integration
      local cmp_autopairs = require "nvim-autopairs.completion.cmp"
      local cmp = require "cmp"
      cmp.event:on("confirm_done", cmp_autopairs.on_confirm_done())
    end,
  },
}

return plugins
