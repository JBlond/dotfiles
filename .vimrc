if has('win32') || has('win64')
	source $VIMRUNTIME/mswin.vim
endif

:set hidden

set encoding=utf-8
set ruler
set nu
set nowrap
set nobackup " no *~ backup files

set tabstop=4
set shiftwidth=4
set autoindent

set ignorecase
set smartcase
set infercase
set incsearch
set hlsearch
set wildignore+=*.o,*.obj,*.exe,*.so,*.dll,*.pyc,.svn,.hg,.bzr,.git,.sass-cache,*.class

set showmatch   " Show matching brackets.
set matchtime=2 " How many tenths of a second to blink
set list        " show tab and trail
set listchars=tab:▸\ ,trail:¬
