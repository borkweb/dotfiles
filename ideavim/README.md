# IdeaVim

IdeaVim is a Vim emulation plugin for IDEs based on the IntelliJ platform. Here are the key things to know about
my own implementation.

## Prerequisites

1. Install the IdeaVim plugin in your IDE.
2. Install the `IdeaVim-Quickscope` plugin
3. Install the `IdeaVim-EasyMotion` plugin
4. Install the `IdeaVimExtension` plugin
5. Install the `IdeaVimMulticursor` plugin
6. Install the `Which-Key` plugin

## Setup

Place `.ideavimrc` in your home directory.

```bash
cd ~
ln -s ~/git/dotfiles/ideavim/.ideavimrc .ideavimrc
```

## Plugins

This setup uses the following vim plugins:

* [commentary](https://github.com/tpope/vim-commentary) - Handy commenting utility
* [easymotion](https://github.com/easymotion/vim-easymotion) - Provides easy navigation to different parts of the file
* [highlightedyank](https://github.com/machakann/vim-highlightedyank) - Highlights the yanked text
* [NERDTree](https://github.com/preservim/nerdtree) - File navigation
* [surround](https://github.com/tpope/vim-surround) - Surround strings with characters or HTML tags
* [which-key](https://github.com/liuchengxu/vim-which-key) - Provides helpful hints for keybindings when you press your `<leader>` key.

## Commands

### General

#### Any mode

* `<C-w><C-w>` - Switch between windows
* `<C-h>` - Move to the window to the left
* `<C-j>` - Move to the window below
* `<C-k>` - Move to the window above
* `<C-l>` - Move to the window to the right

#### Normal mode

* `]` - Opens the next menu in Which-Key
* `[` - Opens the previous menu in Which-Key
* `<C-x>` - Hide all IntelliJ windows
* `<C-s>` - Open the file structure
* `<C-t>` - Open the terminal
* `g` - Opens the goto menu in Which-Key
* `m` - Opens the mark menu in Which-Key
* `mA` - `mZ` - Set a mark from `A` to `Z`

#### Visual mode

* `<S-J>` (shift + j) - Move line(s) down
* `<S-K>` (shift + k) - Move line(s) up

### Commentary

* `gcc` - (Un)comment out the current line

### Surround

#### Visual mode

* `<S-S>` (shift + s) - Surround the selected text with a character or HTML tag