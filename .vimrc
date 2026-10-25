set nocompatible              " be iMproved, required
filetype off                  " required

let mapleader = ","
let maplocalleader = ","

" set the runtime path to include Vundle and initialize
set rtp+=~/.vim/bundle/Vundle.vim
call vundle#begin()
" alternatively, pass a path where Vundle should install plugins
"call vundle#begin('~/some/path/here')

" let Vundle manage Vundle, required
Plugin 'VundleVim/Vundle.vim'

" Keep Plugin commands between vundle#begin/end.
" plugin on GitHub repo
Plugin 'tpope/vim-fugitive'
Plugin 'preservim/nerdtree'
Plugin 'vim-airline/vim-airline'
Plugin 'tomasiser/vim-code-dark'
Plugin 'sheerun/vim-polyglot'

" All of your Plugins must be added before the following line
call vundle#end()            " required
filetype plugin indent on    " required
" To ignore plugin indent changes, instead use:
"filetype plugin on
"
" Brief help
" :PluginList       - lists configured plugins
" :PluginInstall    - installs plugins; append `!` to update or just :PluginUpdate
" :PluginSearch foo - searches for foo; append `!` to refresh local cache
" :PluginClean      - confirms removal of unused plugins; append `!` to auto-approve removal
"
" see :h vundle for more details or wiki for FAQ
" Put your non-Plugin stuff after this line

colorscheme codedark

set modelines=0
set number						" show line numbers
set ruler							" show line and column number of cursor in statusline
set visualbell				" visual bell instead of beeping when doing something wrong
set encoding=utf-8
set nowrap
set scrolloff=2				" Keep 2 lines visible above/below curosr when moving around
set tabstop=2					" width that a <TAB> character displays as
set autoindent
set copyindent
set smartindent
set cursorline
set autoread					" autoreload the file in vim if it has been changed outside of vim

set listchars=tab:▸\ ,eol:¬
set list

set ignorecase
set smartcase
set incsearch					" search as characters are entered
set hlsearch					" highlight matches

nnoremap <CR> :nohlsearch<CR><CR>		" turn off search highlihgting with <CR>

" Bring search results to midscreen
nnoremap n nzz
nnoremap N Nzz
