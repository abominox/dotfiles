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
"# Bash Script Linter (shellcheck)
let g:syntastic_sh_checkers = ['shellcheck']

"# Boilerplate settings for Syntastic
set statusline+=%#warningmsg#
set statusline+=%{SyntasticStatuslineFlag()}
set statusline+=%*
let g:syntastic_always_populate_loc_list = 1
let g:syntastic_auto_loc_list = 1
let g:syntastic_check_on_open = 1
let g:syntastic_check_on_wq = 0

"#### tmux Settings

"#### Pathogen / Plugin Settings
"# Enable Pathogen
execute pathogen#infect()

"#### Misc
