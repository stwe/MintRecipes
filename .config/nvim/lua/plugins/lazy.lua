-- Bootstrap lazy.nvim
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not (vim.uv or vim.loop).fs_stat(lazypath) then
    local lazyrepo = "https://github.com/folke/lazy.nvim.git"
    local out = vim.fn.system({ "git", "clone", "--filter=blob:none", "--branch=stable", lazyrepo, lazypath })
    if vim.v.shell_error ~= 0 then
        vim.api.nvim_echo({
            { "Failed to clone lazy.nvim:\n", "ErrorMsg" },
            { out,                            "WarningMsg" },
            { "\nPress any key to exit..." },
        }, true, {})
        vim.fn.getchar()
        os.exit(1)
    end
end
vim.opt.rtp:prepend(lazypath)

-- Setup lazy.nvim
require("lazy").setup({
    spec = {
        { "catppuccin/nvim", name = "catppuccin", priority = 1000 },
        {
            'nvim-telescope/telescope.nvim',
            tag = '0.1.8',
            dependencies = { 'nvim-lua/plenary.nvim' }
        },
        {
            "nvim-tree/nvim-tree.lua",
            version = "*",
            lazy = false,
            dependencies = {
                "nvim-tree/nvim-web-devicons",
            },
            config = function()
                require("nvim-tree").setup {}
            end,
        },
        {
            'nvim-lualine/lualine.nvim',
            dependencies = { 'nvim-tree/nvim-web-devicons' },
            config = function()
                require("lualine").setup {}
            end,
        },
        {
            'nvimdev/dashboard-nvim',
            event = 'VimEnter',
            config = function()
                require('dashboard').setup {}
            end,
            dependencies = { { 'nvim-tree/nvim-web-devicons' } }
        },
        {
            "lewis6991/gitsigns.nvim",
            dependencies = { "nvim-lua/plenary.nvim" },
            config = function()
                require('gitsigns').setup {
                    signs = {
                        add = { text = '│' },
                        change = { text = '│' },
                        delete = { text = '_' },
                        topdelete = { text = '‾' },
                        changedelete = { text = '~' }
                    },
                    signcolumn = true,
                    numhl = false,
                    linehl = false,
                }
            end,
        },
        {
            {
                'williamboman/mason.nvim',
                lazy = false,
                opts = {},
            },

            -- Autocompletion
            {
                'hrsh7th/nvim-cmp',
                event = { "InsertEnter", "CmdlineEnter" },
                config = function()
                    local cmp = require('cmp')

                    cmp.setup({
                        sources = {
                            { name = 'nvim_lsp' },
                        },
                        mapping = cmp.mapping.preset.insert({
                            ['<C-Space>'] = cmp.mapping.complete(),
                            ['<C-u>'] = cmp.mapping.scroll_docs(-4),
                            ['<C-d>'] = cmp.mapping.scroll_docs(4),
                            ['<Tab>'] = cmp.mapping.select_next_item(),
                            ['<S-Tab>'] = cmp.mapping.select_prev_item(),
                        }),
                        snippet = {
                            expand = function(args)
                                vim.snippet.expand(args.body)
                            end,
                        },
                    })
                end
            },

            -- LSP
            {
                'neovim/nvim-lspconfig',
                cmd = { 'LspInfo', 'LspInstall', 'LspStart' },
                event = { 'BufReadPre', 'BufNewFile' },
                dependencies = {
                    { 'hrsh7th/cmp-nvim-lsp' },
                    { 'williamboman/mason.nvim' },
                    { 'williamboman/mason-lspconfig.nvim' },
                },
                init = function()
                    -- Reserve a space in the gutter
                    -- This will avoid an annoying layout shift in the screen
                    vim.opt.signcolumn = 'yes'
                end,
                config = function()
                    local lsp_defaults = require('lspconfig').util.default_config

                    -- Add cmp_nvim_lsp capabilities settings to lspconfig
                    -- This should be executed before you configure any language server
                    lsp_defaults.capabilities = vim.tbl_deep_extend(
                        'force',
                        lsp_defaults.capabilities,
                        require('cmp_nvim_lsp').default_capabilities()
                    )

                    -- LspAttach is where you enable features that only work
                    -- if there is a language server active in the file
                    vim.api.nvim_create_autocmd('LspAttach', {
                        desc = 'LSP actions',
                        callback = function(event)
                            local opts = { buffer = event.buf }

                            vim.keymap.set('n', 'K', '<cmd>lua vim.lsp.buf.hover()<cr>', opts)
                            vim.keymap.set('n', 'gd', '<cmd>lua vim.lsp.buf.definition()<cr>', opts)
                            vim.keymap.set('n', 'gD', '<cmd>lua vim.lsp.buf.declaration()<cr>', opts)
                            vim.keymap.set('n', 'gi', '<cmd>lua vim.lsp.buf.implementation()<cr>', opts)
                            vim.keymap.set('n', 'go', '<cmd>lua vim.lsp.buf.type_definition()<cr>', opts)
                            vim.keymap.set('n', 'gr', '<cmd>lua vim.lsp.buf.references()<cr>', opts)
                            vim.keymap.set('n', 'gs', '<cmd>lua vim.lsp.buf.signature_help()<cr>', opts)
                            vim.keymap.set('n', '<F2>', '<cmd>lua vim.lsp.buf.rename()<cr>', opts)
                            vim.keymap.set({ 'n', 'x' }, '<F3>', '<cmd>lua vim.lsp.buf.format({async = true})<cr>', opts)
                            vim.keymap.set('n', '<F4>', '<cmd>lua vim.lsp.buf.code_action()<cr>', opts)
                        end,
                    })

                    require('mason-lspconfig').setup({
                        ensure_installed = {},
                        handlers = {
                            -- this first function is the "default handler"
                            -- it applies to every language server without a "custom handler"
                            function(server_name)
                                require('lspconfig')[server_name].setup({})
                            end,
                        }
                    })
                end
            }
        }
    }, -- end spec

    -- Configure any other settings here. See the documentation for more details.
    -- colorscheme that will be used when installing plugins.
    install = { colorscheme = { "habamax" } },
    -- automatically check for plugin updates
    checker = { enabled = true },
})
