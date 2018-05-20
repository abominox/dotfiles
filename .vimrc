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

"#### Syntastic Settings
"# Python 3 Linter (pylint)
let g:syntastic_python_checkers = ['pylint']
"# YAML Linter (yamllint)
let g:syntastic_yaml_checkers = ['yamllint']

"# Boilerplate settings for Syntastic
set statusline+=%#warningmsg#
set statusline+=%{SyntasticStatuslineFlag()}
set statusline+=%*
let g:syntastic_always_populate_loc_list = 1
let g:syntastic_auto_loc_list = 1
let g:syntastic_check_on_open = 1
let g:syntastic_check_on_wq = 0

"#### tmux Settings
"let g:tmuxline_powerline_separators = 0
"# Prevent tmuxline from CRUSHING my custom status line
let g:airline#extensions#tmuxline#enabled = 0

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
