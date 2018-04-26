" abominox's .vimrc file

"#### General Settings
set encoding=utf-8
set laststatus=2
set nu
syntax on
filetype plugin on

"#### Color Settings
colorscheme badwolf
"# Next three lines ensure badwolf,
" a gvim theme, adds no bg color
hi Normal guibg=NONE ctermbg=NONE
highlight NonText ctermbg=none
hi lineNr ctermbg=none

"#### tmux Settings
"# Enable the tmux Airline coloring
let g:tmuxline_powerline_separators = 0
"# Set tmuxline coloring without starting vim first
let g:airline#extensions#tmuxline#enabled = 1
let airline#extensions#tmuxline#snapshot_file = "~/.tmux.conf"

"#### Pathogen / Plugin Settings
"# Enable Pathogen
execute pathogen#infect()

"#### Vim Airline
"# Enable powerline fonts (does not work)
"let g:airline_powerline_fonts = 1

"#### Misc


"#### Deprecated
"set rtp+=$HOME/.local/lib/python2.7/site-packages/powerline/bindings/vim/
"# Use 256 colors, if your terminal supports it
"set t_Co=256
