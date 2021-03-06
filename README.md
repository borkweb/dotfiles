# dotfiles
My current dotfiles

## vim

I use [neovim](https://neovim.io/) rather than plain old vim. With it comes some better performing things. Here are the primary plugins that I leverage:

| Plugin | What it does | Frequent commands |
|--|--|--|
| [deoplete.nvim](https://github.com/Shougo/deoplete.nvim) | Auto-completion ||
| [deoplete-phpactor](https://github.com/kristijanhusak/deoplete-phpactor) | Deoplete support for phpactor ||
| [echodoc.vim](https://github.com/Shougo/echodoc.vim) | Auto-completion helper text ||
| [editorconfig-vim](https://github.com/editorconfig/editorconfig-vim) | Observe .editorconfig files ||
| [fzf](https://github.com/fzf) | Fuzzy finder (better ctrlp) | Mapped to `<C-p>` |
| [phpfolding.vim](https://github.com/vim-scripts/phpfolding.vim) | Auto-code folding for PHP | |
| [nerdcommenter](https://github.com/preservim/nerdcommenter) | Handy commenting utility | Comment: `<leader>cc`, Uncomment: `<leader>cu` |
| [nerdtree](https://github.com/perservim/nerdtree) | File navigation | Toggle: `<C-n>` |
| [phpactor](https://github.com/phpactor/phpactor) | PHP auto-completion support ||
| [tagbar](https://github.com/majutsushi/tagbar) | File structure navigation | Toggle: `<C-k><C-t>` |
| [ultisnips](https://github.com/SirVer/ultisnips) | Snippets ||
| [undotree](https://github.com/mbbill/undotree) | Provide a visual undo tree | Toggle mapped to `F1` (see my [mappings.vim](.vim/core/mappings.vim)) |
| [vdebug](https://github.com/vim-vdebug/vdebug) | Debugging/breakpoints (xdebug) | `F2` through `F12` (but not `F8`) |
| [vim-airline](https://github.com/vim-airline) | Pretty vim UI ||
| [vim-airline-themes](https://github.com/vim-airline-themes) | Pretty vim UI ||
| [vim-gitgutter](https://github.com/airblade/vim-gitgutter) | Add git status for lines in the vim editor's gutter | |
| [vim-polyglot](https://github.com/sheerun/vim-polyglot) | Syntax support for a lot of languages ||
| [vim-surround](https://github.com/tpope/vim-surround) | Surround strings with characters or HTML tags | Change `"` to `'`: `cs"'` |
| [vim-tmux-navigator](https://github.com/christoomey/vim-tmux-navigator) | Seamlessly navigate between vim and tmux panels | `<C-h>`, `<C-j>`, `<C-k>`, and `<C-l>` |


## tmux configuration

In my terminal, on launch I run the following command to launch with a tmux session called `main` for the first terminal that I open and subsequent terminals will not have tmux running by default.

```
/usr/bin/zsh -c "if ! tmux ls 2>/dev/null | grep -q -E '^main.*attached'; then tmux attach -t main || tmux new -s main; else /usr/bin/zsh; fi"
```
