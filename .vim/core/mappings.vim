let mapleader=","

:nnoremap <leader>i :setl noai nocin nosi inde=<CR>

" go back # words
map <leader>b :b#<CR>

" makes the current window wider by 10 characters
map <leader>] 10<C-W>>

" makes the current window smaller by 10 characters
map <leader>[ 10<C-W><

" toggle showing of line numbers
map <silent> <leader>L :se nu!<CR>

nmap <leader>s :source ~/.vimrc<CR>

" Sort CSS properties
nnoremap <leader>S ?{<CR>jV/^\s*\}?$<CR>k:sort<CR>:noh<CR>

" re-select text that was just pasted
nnoremap <leader>v V`]

map K <Nop>

" open a new tab
map <leader>t <Esc>:tabnew<CR>

" Strip all trailing whitespace
nnoremap <leader>W :%s/\s\+$//<cr>:let @/=''<CR>

" Underline the current line with '='
nmap <silent> <leader>ul :t.\|s/./=/g\|:nohls<cr>

" find merge conflict markers
nmap <silent> <leader>fc <ESC>/\v^[<=>]{7}( .*\|$)<CR>

" Adjust viewports to the same size
map <Leader>= <C-w>=

" Superuser write
cnoremap w!! w !sudo dd of=%

" Use perl compatible regex formatting...not vim style
nnoremap / /\v
vnoremap / /\v

" Make j and k move one line at a time, even on wrapped lines
nnoremap j gj
nnoremap k gk

" Use leader space to clear a search term
nnoremap <leader><space> :noh<cr>

nnoremap <silent> <Space> @=(foldclosed('.')!=-1?'za':'l')<CR>
vnoremap <Space> zf

" Switch windows with ctrl + hjkl
map <C-h> <C-w>h
map <C-j> <C-w>j
map <C-k> <C-w>k
map <C-l> <C-w>l

" Toggle the awesome undo tree visualizer
map <F1> :UndotreeToggle<CR>

map <C-n> :NERDTreeToggle<CR>

" Allow for the copying of the selected text using xclip
vnoremap <C-c> :w !xclip -i -sel c<CR><CR>

nnoremap <silent> <C-K><C-T> :TagbarToggle<CR>

nmap <C-P> :FZF<CR>

" Jump to the definition of a function
nnoremap <leader>d vt(<C-]>
