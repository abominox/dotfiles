" abominox's .vimrc file

"#### General Settings
set encoding=utf-8
set laststatus=2
set nu
syntax on
filetype plugin on
let g:netrw_dirhistmax=0
set noerrorbells
set tabstop=4 softtabstop=4
set shiftwidth=4
set smartindent
set incsearch
set noswapfile

"#### Color Settings
colorscheme badwolf
"# Next three lines ensure badwolf,
" a gvim theme, adds no bg color
hi Normal guibg=NONE ctermbg=NONE
highlight NonText ctermbg=none
hi lineNr ctermbg=none

"#### tmux Settings

"#### Plugin Settings (vim-plug)
call plug#begin('~/.vim/bundle')
Plug 'vim-airline/vim-airline'
Plug 'vim-airline/vim-airline-themes'
call plug#end()

"#### Misc
" Auto-indent after carriage return on yaml files
autocmd FileType yaml setlocal ts=2 sts=2 sw=2 expandtab
