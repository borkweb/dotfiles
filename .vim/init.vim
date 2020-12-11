""
"" Basic Setup
""

set nocompatible   " Use vim, no vi defaults
set number         " Show line numbers
set ruler          " Show line and column number
set encoding=utf-8 " Set default encoding to UTF-8
set visualbell
set cursorline     " highlight the line the cursor is on
set ttyfast        " helps with repaint
set laststatus=2   " 2 means all windows will always have a status line
set textwidth=0    " don't auto-wrap lines

""
"" Whitespace
""
set nowrap                     " don't wrap lines
set backspace=indent,eol,start " backspace through everything in insert mode
set autoindent                 " Automatic indentation
set list                       " Show invisible characters
set tabstop=2                  " a tab is 2 spaces
set softtabstop=2              " tab width while in insert mode
set shiftwidth=2               " number of spaces to use for autoindenting
set wrapscan                   " wrap a whole word to the next line

""
"" List chars - show hidden characters
""
set listchars=""                  " Reset the listchars
set listchars=eol:¬               " end of line should have ¬
set listchars+=tab:»\             " a tab should display as "» ", trailing whitespace as "."
set listchars+=trail:·            " show trailing spaces as dots
set listchars+=extends:>          " The character to show in the last column when wrap is
                                  " off and the line continues beyond the right of the screen
set listchars+=precedes:<         " The character to show in the last column when wrap is
                                  " off and the line continues beyond the right of the screen

""
"" Search Settings
""
set hlsearch    " Highlight all search terms
set incsearch   " While typing a search command, show where the pattern - as it was typed - matches
set ignorecase  " Ignore case when searching
set smartcase   " Override the ignorecase option if the search pattern contains uppercase characters
set showmatch   " When a bracket is inserted, briefly jump to the matching one if on the screen
set matchtime=3 " 10ths of a second to show the matching paren

""
"" Misc Settings
""
set iskeyword-=_     " Include underscores as part of keyword names
set isfname+=_       " Include underscores as part of filenames
set updatecount=50   " After this many characters, write the swp file to disk
set ffs=unix,dos,mac " Sets the EOL format
set pastetoggle=<F2> " Set a key for toggling paste mode
set nocindent        " Disables automattic C program indenting
set hidden
set modeline
set modelines=5
set splitbelow       " always put horizontal splits at the bottom
set splitright       " always put vertical splits on the right
set sidescrolloff=15 " start scrolling on the side if we are 15 characters from the edge
set sidescroll=1
set tags=./tags;,tags;./.tags;,.tags;
set noshowmode       " Hide the mode display so that echodoc.vim can display function signatures

" Or, you could use neovim's floating text feature.
let g:echodoc#enable_at_startup = 1
let g:echodoc#type = 'virtual'

let g:deoplete#enable_at_startup = 1
let g:wphooks_dir = '/home/matt/.vim/plugged/deoplete-wp-hooks/wp-hooks/'

" To ensure that this plugin works well with Tim Pope's fugitive, use the following patterns array:
let g:EditorConfig_exclude_patterns = ['fugitive://.*']

source ~/.vim/core/plugins.vim
source ~/.vim/core/autocmd.vim
source ~/.vim/core/diff.vim
source ~/.vim/core/filetypes.vim
source ~/.vim/core/mappings.vim
source ~/.vim/core/vdebug.vim

""
"" fzf (Fuzzy Finder) config
""
" [Tags] Command to generate tags file
let g:fzf_tags_command = 'ctags -R'

""
"" Colors & Theme
""
syntax enable
set background=dark

" tmux compatibility
set t_8f=^[[38;2;%lu;%lu;%lum
set t_8b=^[[48;2;%lu;%lu;%lum

colorscheme bork

" Set background to transparent
hi Normal         guibg=NONE ctermbg=NONE
hi SpecialKey     guibg=NONE ctermbg=NONE
hi VertSplit      guibg=NONE ctermbg=NONE
hi SignColumn     guibg=NONE ctermbg=NONE
hi NonText        guibg=NONE ctermbg=NONE
hi Directory      guibg=NONE ctermbg=NONE
hi Title          guibg=NONE ctermbg=NONE
hi ColorColumn    guibg=#111111 ctermbg=NONE

" -> Folding
hi FoldColumn     guibg=NONE ctermbg=NONE
hi Folded         guibg=NONE ctermbg=NONE

" -> Code
hi Comment        guibg=NONE ctermbg=NONE
hi Constant       guibg=NONE ctermbg=NONE
hi String         guibg=NONE ctermbg=NONE
hi Error          guibg=NONE ctermbg=NONE
hi Identifier     guibg=NONE ctermbg=NONE
hi Function       guibg=NONE ctermbg=NONE
hi Ignore         guibg=NONE ctermbg=NONE
hi MatchParen     guibg=NONE ctermbg=NONE
hi PreProc        guibg=NONE ctermbg=NONE
hi Special        guibg=NONE ctermbg=NONE
hi Todo           guibg=NONE ctermbg=NONE
hi Underlined     guibg=NONE ctermbg=NONE
hi Statement      guibg=NONE ctermbg=NONE
hi Operator       guibg=NONE ctermbg=NONE
hi Delimiter      guibg=NONE ctermbg=NONE
hi Type           guibg=NONE ctermbg=NONE
hi Exception      guibg=NONE ctermbg=NONE

" -> HTML-specific
hi htmlBold                 guibg=NONE ctermbg=NONE
hi htmlBoldItalic           guibg=NONE ctermbg=NONE
hi htmlBoldUnderline        guibg=NONE ctermbg=NONE
hi htmlBoldUnderlineItalic  guibg=NONE ctermbg=NONE
hi htmlItalic               guibg=NONE ctermbg=NONE
hi htmlUnderline            guibg=NONE ctermbg=NONE
hi htmlUnderlineItalic      guibg=NONE ctermbg=NONE

set suffixes=.bak,~,.o,.h,.info,.swp,.obj,.pyc

call neomake#configure#automake('nrwi', 500)
