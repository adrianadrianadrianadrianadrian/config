vim.g.mapleader = " "
vim.g.maplocalleader = " "
vim.opt.mouse = ""
vim.opt.clipboard = "unnamedplus"
vim.opt.breakindent = true
vim.opt.undofile = true
vim.opt.ignorecase = true
vim.opt.smartcase = true
vim.opt.signcolumn = "yes"
vim.opt.updatetime = 250
vim.opt.timeoutlen = 300
vim.opt.splitright = true
vim.opt.splitbelow = true
vim.opt.inccommand = "split"
vim.opt.cursorline = true
vim.opt.scrolloff = 20
vim.opt.hlsearch = true
vim.cmd 'colorscheme quieter'
vim.opt.tabstop = 4
vim.opt.softtabstop = 4
vim.opt.shiftwidth = 4
vim.opt.expandtab = true
vim.opt.guicursor = ""

vim.api.nvim_create_autocmd("TextYankPost", {
    desc = "Highlight when yanking (copying) text",
    group = vim.api.nvim_create_augroup("highlight-yank", { clear = true }),
    callback = function()
        vim.highlight.on_yank()
    end,
})

vim.api.nvim_create_autocmd("Filetype", {
    callback = function()
        vim.opt_local.autoindent = false
        vim.opt_local.cindent = false
        vim.opt_local.smartindent = false
        vim.opt_local.indentexpr = ""
        vim.opt.cursorline = false
    end,
})

local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.loop.fs_stat(lazypath) then
    local lazyrepo = "https://github.com/folke/lazy.nvim.git"
    vim.fn.system({ "git", "clone", "--filter=blob:none", "--branch=stable", lazyrepo, lazypath })
end
vim.opt.rtp:prepend(lazypath)
vim.diagnostic.config({ virtual_text = false })

require("lazy").setup({
    -- Commenting
    { "numToStr/Comment.nvim", opts = {} },

    -- Fuzzy Finder
    {
        "nvim-telescope/telescope.nvim",
        event = "VimEnter",
        branch = "0.1.x",
        dependencies = {
            "nvim-lua/plenary.nvim",
        },
        config = function()
            require("telescope").setup({
                defaults = {
                    mappings = {
                        i = { ['<C-j>'] = 'move_selection_next', ['<C-k>'] = 'move_selection_previous' },
                    },
                },
            })

            local builtin = require("telescope.builtin")
            vim.keymap.set("n", "<leader>sf", builtin.find_files,
                { desc = "[S]earch [F]iles" })
            vim.keymap.set("n", "<leader>sg", builtin.live_grep,
                { desc = "[S]earch by [G]rep" })
        end,
    },

    -- LSP Configuration & Plugins
    {
        "neovim/nvim-lspconfig",
        dependencies = {
            "williamboman/mason.nvim",
            "williamboman/mason-lspconfig.nvim",
            "WhoIsSethDaniel/mason-tool-installer.nvim",
            { "j-hui/fidget.nvim", opts = {} },
            { "folke/neodev.nvim", opts = {} },
        },
        config = function()
            vim.api.nvim_create_autocmd("LspAttach", {
                group = vim.api.nvim_create_augroup(
                    "kickstart-lsp-attach", { clear = true }),
                callback = function(event)
                    local map = function(keys, func, desc)
                        vim.keymap.set("n", keys,
                            func,
                            {
                                buffer = event.buf,
                                desc = "LSP: " .. desc
                            })
                    end

                    map("gd", goto_definition, "[G]oto [D]efinition")
                    map("gr", goto_references, "[G]oto [R]eferences")
                    map("gI", goto_implementations, "[G]oto [I]mplementation")
                    map("<leader>rn", vim.lsp.buf.rename, "[R]e[n]ame")
                    map("<leader>ca", vim.lsp.buf.code_action, "[C]ode [A]ction")
                    map("K", vim.lsp.buf.hover, "Hover Documentation")
                    map("gD", vim.lsp.buf.declaration, "[G]oto [D]eclaration")
                    map("<leader>f", format, "[F]ormat current buffer")
                end,
            })

            local capabilities = vim.lsp.protocol.make_client_capabilities()
            local servers = {
                clangd = {
                },
                rust_analyzer = {},
                tsserver = {},
                lua_ls = {},
                hls = {
                    settings = {
                        haskell = {
                            formattingProvider = "fourmolu"
                        }
                    }
                },
                omnisharp = {
                    cmd = { "/home/adrian/.local/share/nvim/mason/bin/OmniSharp" },
                },
                pyright = {},
                eslint = {},
                jsonls = {},
                lemminx = {},
                zls = {}
            }

            require("mason").setup()

            local ensure_installed = vim.tbl_keys(servers or {})
            require("mason-tool-installer").setup({
                ensure_installed =
                    ensure_installed
            })

            require("mason-lspconfig").setup({
                handlers = {
                    function(server_name)
                        local server = servers
                            [server_name] or {}
                        server.capabilities = vim
                            .tbl_deep_extend(
                                "force",
                                {},
                                capabilities,
                                server.capabilities or
                                {})
                        require("lspconfig")
                            [server_name].setup(
                            server)
                    end,
                },
            })
        end,
    },

    -- -- Autocompletion
    {
        "hrsh7th/nvim-cmp",
        event = "InsertEnter",
        dependencies = {
            {
                "L3MON4D3/LuaSnip",
                build = (function()
                    if vim.fn.has("win32") == 1 or vim.fn.executable("make") == 0 then
                        return
                    end
                    return "make install_jsregexp"
                end)(),
            },
            "saadparwaiz1/cmp_luasnip",
            "hrsh7th/cmp-nvim-lsp",
            "hrsh7th/cmp-path",
        },
        config = function()
            local cmp = require("cmp")
            local luasnip = require("luasnip")
            luasnip.config.setup({})

            cmp.setup({
                snippet = {
                    expand = function(args)
                        luasnip.lsp_expand(args
                            .body)
                    end,
                },
                completion = { completeopt = "menu,menuone,noinsert" },
                mapping = cmp.mapping.preset.insert({
                    ["<C-j>"] = cmp.mapping.select_next_item(),
                    ["<C-k>"] = cmp.mapping.select_prev_item(),
                    ['<CR>'] = function(fallback)
                        if cmp.visible() then
                            cmp.confirm()
                        else
                            fallback()
                        end
                    end
                }),
                sources = {
                    { name = "nvim_lsp" },
                    { name = "path" },
                },
            })
        end,
    },

    -- Omnisharp fun
    {
        'Hoffs/omnisharp-extended-lsp.nvim',
        config = function()
            local map = function(keys, func, desc)
                vim.keymap.set("n", keys, func,
                    {
                        buffer = event.buf,
                        desc = "LSP: " .. desc
                    })
            end

            require('omnisharp_extended')
        end
    },

    {
        'prettier/vim-prettier'
    }
}, {})

goto_definition = function()
    if vim.bo.filetype == "cs" then
        require('omnisharp_extended').lsp_definition()
    else
        require("telescope.builtin").lsp_definitions()
    end
end

goto_references = function()
    if vim.bo.filetype == "cs" then
        require('omnisharp_extended').telescope_lsp_references()
    else
        require("telescope.builtin").lsp_references()
    end
end

goto_implementations = function()
    if vim.bo.filetype == "cs" then
        require('omnisharp_extended').telescope_lsp_implementation()
    else
        require("telescope.builtin").lsp_implementations()
    end
end

format = function()
    if vim.bo.filetype == "typescript" or vim.bo.filetype == "typescriptreact" then
        vim.cmd "EslintFixAll"
    elseif vim.bo.filetype == "rust" then
        vim.lsp.buf.format()
    end
end

vim.keymap.set('n', '<leader>d', vim.diagnostic.open_float, { desc = 'Show diagnostic [E]rror messages' })
vim.keymap.set('n', '<leader><leader>', function() vim.cmd "Explore" end, { desc = 'Explore' })
vim.keymap.set('n', '<Esc>', '<cmd>nohlsearch<CR>')
