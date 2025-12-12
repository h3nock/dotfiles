-- ~/.config/nvim/lua/configs/lspconfig.lua
require("nvchad.configs.lspconfig").defaults()

local nvlsp = require "nvchad.configs.lspconfig"

local servers = { "pyright", "ts_ls", "lua_ls", "gopls" }

local capabilities = require("nvchad.configs.lspconfig").capabilities
-- Enhanced capabilities for better completion
capabilities.textDocument.completion.completionItem = {
  documentationFormat = { "markdown", "plaintext" },
  snippetSupport = true,
  preselectSupport = true,
  insertReplaceSupport = true,
  labelDetailsSupport = true,
  deprecatedSupport = true,
  commitCharactersSupport = true,
  tagSupport = { valueSet = { 1 } },
  resolveSupport = {
    properties = {
      "documentation",
      "detail",
      "additionalTextEdits",
    },
  },
}

-- Enable hover and signature help
capabilities.textDocument.hover = {
  dynamicRegistration = true,
  contentFormat = { "markdown", "plaintext" },
}

capabilities.textDocument.signatureHelp = {
  dynamicRegistration = true,
  signatureInformation = {
    documentationFormat = { "markdown", "plaintext" },
    parameterInformation = {
      labelOffsetSupport = true,
    },
  },
}

-- Simple enhanced on_attach
local on_attach = function(client, bufnr)
  nvlsp.on_attach(client, bufnr)

  -- Add signature help in insert mode for better function documentation
  if client.server_capabilities.signatureHelpProvider then
    vim.keymap.set("i", "<C-k>", vim.lsp.buf.signature_help, { buffer = bufnr })
  end
end

-- Enhanced Pyright for better Python IntelliSense
vim.lsp.config.pyright = {
  on_attach = on_attach,
  on_init = nvlsp.on_init,
  capabilities = capabilities,
  settings = {
    python = {
      analysis = {
        typeCheckingMode = "basic",
        autoSearchPaths = true,
        useLibraryCodeForTypes = true,
        diagnosticMode = "workspace",
        completeFunctionParens = true,
        autoImportCompletions = true,
      },
    },
  },
}

-- TypeScript with function completion
vim.lsp.config.ts_ls = {
  on_attach = on_attach,
  on_init = nvlsp.on_init,
  capabilities = capabilities,
  settings = {
    typescript = {
      preferences = { completeFunctionCalls = true },
    },
    javascript = {
      preferences = { completeFunctionCalls = true },
    },
  },
}

-- Lua with essential Neovim globals
vim.lsp.config.lua_ls = {
  on_attach = on_attach,
  on_init = nvlsp.on_init,
  capabilities = capabilities,
  settings = {
    Lua = {
      diagnostics = { globals = { "vim" } },
      workspace = {
        library = {
          vim.fn.expand "$VIMRUNTIME/lua",
          vim.fn.expand "$VIMRUNTIME/lua/vim/lsp",
          vim.fn.stdpath "data" .. "/lazy/lazy.nvim/lua/lazy",
        },
        checkThirdParty = false,
      },
      completion = { callSnippet = "Replace" },
      telemetry = { enable = false },
    },
  },
}

-- Go with essential features
vim.lsp.config.gopls = {
  on_attach = on_attach,
  on_init = nvlsp.on_init,
  capabilities = capabilities,
  settings = {
    gopls = {
      completeUnimported = true,
      usePlaceholders = true,
      analyses = { unusedparams = true },
    },
  },
}

-- Enable all servers
for _, server in ipairs(servers) do
  vim.lsp.enable(server)
end

-- Better diagnostic display
vim.diagnostic.config {
  virtual_text = { prefix = "●" },
  float = { border = "rounded", source = true },
  signs = true,
  underline = true,
  severity_sort = true,
}
