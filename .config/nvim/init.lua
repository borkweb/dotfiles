-- Ported from ~/.vimrc

vim.g.mapleader = ","
vim.g.maplocalleader = ","

-- Bootstrap lazy.nvim
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not (vim.uv or vim.loop).fs_stat(lazypath) then
  vim.fn.system({
    "git", "clone", "--filter=blob:none",
    "https://github.com/folke/lazy.nvim.git",
    "--branch=stable", lazypath,
  })
end
vim.opt.rtp:prepend(lazypath)

-- Plugins (equivalents to the Vundle list)
require("lazy").setup({
  "tpope/vim-fugitive",
  "preservim/nerdtree",
  "vim-airline/vim-airline",
  { "tomasiser/vim-code-dark", priority = 1000 },
  "sheerun/vim-polyglot",
  {
    "lucatume/agent-ask.nvim",
    keys = {
      { "<leader>aa", mode = { "n", "v" }, desc = "agent: ask" },
      { "<leader>af", mode = "n",          desc = "agent: send" },
      { "<leader>al", mode = "n",          desc = "agent: list" },
    },
    config = function()
      require("agent-ask").setup({})
    end,
  },
}, {
  install = { colorscheme = { "codedark" } },
  change_detection = { notify = false },
})

vim.cmd.colorscheme("codedark")

-- Options
vim.opt.modelines = 0
vim.opt.number = true            -- show line numbers
vim.opt.ruler = true             -- show line and column number of cursor
vim.opt.visualbell = true        -- visual bell instead of beeping
vim.opt.encoding = "utf-8"
vim.opt.wrap = false
vim.opt.scrolloff = 2            -- keep 2 lines visible above/below cursor
vim.opt.tabstop = 2              -- width of <TAB> character
vim.opt.autoindent = true
vim.opt.copyindent = true
vim.opt.smartindent = true
vim.opt.cursorline = true
vim.opt.autoread = true          -- autoreload file if changed outside nvim

vim.opt.listchars = { tab = "▸ ", eol = "¬" }
vim.opt.list = true

vim.opt.ignorecase = true
vim.opt.smartcase = true
vim.opt.incsearch = true         -- search as characters are entered
vim.opt.hlsearch = true          -- highlight matches

-- Mappings
vim.keymap.set("n", "<CR>", ":nohlsearch<CR><CR>", { silent = true })
vim.keymap.set("n", "n", "nzz")  -- bring search results to midscreen
vim.keymap.set("n", "N", "Nzz")
