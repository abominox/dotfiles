# dotfiles
Repository containing my personalized Unix/Linux dotfiles (i3-config, .vimrc, etc.)
Also contains some of my most commonly used linters/other devtools.

### Usage
```bash
cd ~ \
&& git clone https://github.com/abominox/dotfiles .dotfiles \
&& cd .dotfiles \
&& ./install.sh
```
If you would like to install just the dotfiles (no devtools, no sudo access), simply pass 
the 'minimal' argument when invoking the script.
```bash
./install.sh minimal
```
