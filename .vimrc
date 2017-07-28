" Christopher Marquart's .vimrc file


"####### statusline configurations

set encoding=utf-8
set laststatus=2
set statusline=%t       "tail of the filename
set statusline+=[%{strlen(&fenc)?&fenc:'none'}, "file encoding
set statusline+=%{&ff}] "file format
set statusline+=%h      "help file flag
set statusline+=%m      "modified flag
set statusline+=%r      "read only flag
set statusline+=%y      "filetype
set statusline+=%=      "left/right separator
set statusline+=%c,     "cursor column
set statusline+=%l/%L   "cursor line/total lines
set statusline+=\ %P    "percent through file

"should remove statusline's white bg color, does not work yet
"hi StatusLine ctermbg=NONE cterm=NONE "remove statusline bg color

"other configurations

set nu
":set cursorline
set ruler
filetype indent on
syntax on
colorscheme desert

"Pathogen plugin manager settings
execute pathogen#infect()
filetype plugin indent on

"Enable powerline fonts
"let g:airline_powerline_fonts = 1

"####### Powerline config settings

" Use 256 colours (Use this setting only if your terminal supports 256
" colours)
set t_Co=256

set rtp+=$HOME/.local/lib/python2.7/site-packages/powerline/bindings/vim/
