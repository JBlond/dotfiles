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
set showmode  " Display the mode you're in.
set wildmenu  " Enhanced command line completion.
set wildmode=list:longest " Complete files like a shell.

set ignorecase
set smartcase
set infercase
set incsearch " Highlight matches as you type.
set hlsearch " Highlight matches.
set wildignore+=*.o,*.obj,*.exe,*.so,*.dll,*.pyc,.svn,.hg,.bzr,.git,.sass-cache,*.class

set showmatch   " Show matching brackets.
set matchtime=2 " How many tenths of a second to blink
set list        " show tab and trail
set listchars=tab:»»,trail:.,extends:>,precedes:<