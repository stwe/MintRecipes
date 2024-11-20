vim.opt.encoding = "utf-8"     -- set encoding
vim.opt.nu = true              -- enable line numbers
vim.opt.relativenumber = false -- relative line numbers

vim.opt.tabstop = 4
vim.opt.softtabstop = 4
vim.opt.shiftwidth = 4
vim.opt.expandtab = true  -- convert tabs to spaces
vim.opt.autoindent = true -- auto indentation
vim.opt.list = true       -- show tab characters and trailing whitespace
vim.opt.listchars = { space = '.', tab = '▸ ', trail = '~', nbsp = '␣' }

vim.opt.termguicolors = true -- enable true color support

vim.opt.clipboard = "unnamed,unnamedplus"
