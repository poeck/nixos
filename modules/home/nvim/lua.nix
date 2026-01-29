{ config, pkgs, ... }:
{
  config.programs.nixvim.extraConfigLua = ''
    -- Load snippets
    require("luasnip.loaders.from_vscode").lazy_load()

    -- Set up capabilities for blink.cmp
    local capabilities = require("blink.cmp").get_lsp_capabilities()

    -- Format on save
    vim.api.nvim_create_autocmd("BufWritePre", {
      pattern = "*",
      callback = function(args)
        require("conform").format({ bufnr = args.buf })
      end,
    })

    -- LSP servers
    vim.lsp.config("nixd", { capabilities = capabilities })
    vim.lsp.config("ts_ls", {
      capabilities = capabilities,
      filetypes = { "javascript", "javascriptreact", "typescript", "typescriptreact" },
      root_dir = vim.fs.root(0, { "package.json", "tsconfig.json", ".git" }),
      settings = {
        typescript = {
          inlayHints = {
            includeInlayParameterNameHints = "all",
            includeInlayFunctionParameterTypeHints = true,
            includeInlayVariableTypeHints = true,
            includeInlayPropertyDeclarationTypeHints = true,
            includeInlayFunctionLikeReturnTypeHints = true,
          },
        },
      },
    })
    vim.lsp.config("tailwindcss", {
      capabilities = capabilities,
      filetypes = { "html", "css", "scss", "javascript", "javascriptreact", "typescript", "typescriptreact" },
      root_dir = vim.fs.root(0, { "tailwind.config.js", "tailwind.config.ts", "postcss.config.js", "postcss.config.ts", ".git" }),
    })
    vim.lsp.config("html", {
      capabilities = capabilities,
      filetypes = { "html" },
    })
    vim.lsp.config("cssls", {
      capabilities = capabilities,
      filetypes = { "css", "scss" },
    })
    vim.lsp.config("eslint", {
      capabilities = capabilities,
      filetypes = { "javascript", "javascriptreact", "typescript", "typescriptreact" },
      root_dir = vim.fs.root(0, { ".eslintrc.js", ".eslintrc.cjs", ".eslintrc.yaml", ".eslintrc.yml", ".eslintrc.json", ".git" }),
    })
    vim.lsp.config("jsonls", {
      capabilities = capabilities,
      filetypes = { "json" },
    })

    -- Enable LSP servers on file open
    vim.api.nvim_create_autocmd("FileType", {
      pattern = { "javascript", "javascriptreact", "typescript", "typescriptreact" },
      callback = function(args)
        vim.lsp.enable("ts_ls", "tailwindcss", "eslint")
      end,
    })

    vim.api.nvim_create_autocmd("FileType", {
      pattern = { "html" },
      callback = function(args)
        vim.lsp.enable("html", "tailwindcss")
      end,
    })

    vim.api.nvim_create_autocmd("FileType", {
      pattern = { "css", "scss" },
      callback = function(args)
        vim.lsp.enable("cssls", "tailwindcss")
      end,
    })

    vim.api.nvim_create_autocmd("FileType", {
      pattern = { "nix" },
      callback = function(args)
        vim.lsp.enable("nixd")
      end,
    })

    -- Configure diagnostics to show virtual text
    vim.diagnostic.config({
      virtual_text = true,
      signs = true,
      underline = true,
      update_in_insert = false,
      severity_sort = true,
    })

    -- LSP keymaps
    vim.api.nvim_create_autocmd("LspAttach", {
      callback = function(args)
        local bufnr = args.buf
        local client = vim.lsp.get_client_by_id(args.data.client_id)

        if client.server_capabilities.definitionProvider then
          vim.keymap.set("n", "gd", function()
            vim.lsp.buf.definition()
          end, { buffer = bufnr, desc = "Go to definition", silent = true })
        end

        if client.server_capabilities.referencesProvider then
          vim.keymap.set("n", "gr", function()
            vim.lsp.buf.references()
          end, { buffer = bufnr, desc = "Go to references", silent = true })
        end

        if client.server_capabilities.hoverProvider then
          vim.keymap.set("n", "K", function()
            vim.lsp.buf.hover()
          end, { buffer = bufnr, desc = "Show hover info", silent = true })
        end

        if client.server_capabilities.codeActionProvider then
          vim.keymap.set("n", "<leader>ca", function()
            vim.lsp.buf.code_action()
          end, { buffer = bufnr, desc = "Code actions", silent = true })
        end

        if client.server_capabilities.renameProvider then
          vim.keymap.set("n", "<leader>rn", function()
            vim.lsp.buf.rename()
          end, { buffer = bufnr, desc = "Rename", silent = true })
        end
      end,
    })

    -- Load telescope-cc extension
    pcall(function()
      require("telescope").load_extension("conventional_commits")
    end)

    -- Configure snacks.nvim
    require("snacks").setup({
      input = {},
      picker = {},
      terminal = {},
    })

    vim.o.autoread = true

    vim.keymap.set({ "n", "x" }, "<C-a>", function() require("opencode").ask("@this: ", { submit = true }) end, { desc = "Ask opencode…" })
    vim.keymap.set({ "n", "x" }, "<C-x>", function() require("opencode").select() end, { desc = "Execute opencode action…" })
    vim.keymap.set({ "n", "t" }, "<C-.>", function() require("opencode").toggle() end, { desc = "Toggle opencode" })

    vim.keymap.set({ "n", "x" }, "go", function() return require("opencode").operator("@this ") end, { desc = "Add range to opencode", expr = true })
    vim.keymap.set("n", "goo", function() return require("opencode").operator("@this ") .. "_" end, { desc = "Add line to opencode", expr = true })

    vim.keymap.set("n", "<S-C-u>", function() require("opencode").command("session.half.page.up") end, { desc = "Scroll opencode up" })
    vim.keymap.set("n", "<S-C-d>", function() require("opencode").command("session.half.page.down") end, { desc = "Scroll opencode down" })

    vim.keymap.set("n", "+", "<C-a>", { desc = "Increment under cursor", noremap = true })
    vim.keymap.set("n", "-", "<C-x>", { desc = "Decrement under cursor", noremap = true })
  '';
}

