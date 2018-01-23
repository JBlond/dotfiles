set nocompatible

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
set copyindent
set showmode  " Display the mode you're in.
set wildmenu  " Enhanced command line completion.
set wildmode=list:longest " Complete files like a shell.
set showcmd  " Show partial commands in the last line of the screen
set laststatus=2  " Always display the status line, even if only one window is displayed
set confirm
set visualbell  " Use visual bell instead of beeping when doing something wrong
set t_vb=  " reset the terminal code for the visual bell.
set mouse=a  " Enable use of the mouse for all modes
set pastetoggle=<F11>  " Use <F11> to toggle between 'paste' and 'nopaste'
nnoremap <C-L> :nohl<CR><C-L>  " Map <C-L> (redraw screen) to also turn off search highlighting until the next search

syntax on
colorscheme monokai
set ignorecase
set smartcase
set infercase
set incsearch " Highlight matches as you type.
set hlsearch " Highlight matches.
set wildignore+=*.o,*.obj,*.exe,*.so,*.dll,*.pyc,.svn,.hg,.bzr,.git,.sass-cache,*.class

set nostartofline
set showmatch   " Show matching brackets.
set matchtime=2 " How many tenths of a second to blink
set list        " show tab and trail
set listchars=tab:»»,trail:.,extends:>,precedes:<

execute pathogen#infect()
filetype plugin indent on

" returns a string <branch/XX> where XX corresponds to the git status
" (for example "<master/ M>")
function CurrentGitStatus()
    let gitoutput = split(system('git status --porcelain -b '.shellescape(expand('%')).' 2>/dev/null'),'\n')
    if len(gitoutput) > 0
        let b:gitstatus = strpart(get(gitoutput,0,''),3) . '/' . strpart(get(gitoutput,1,'  '),0,2)
    else
        let b:gitstatus = ''
    endif
endfunc
autocmd BufEnter,BufWritePost * call CurrentGitStatus()
" example of use in the status line:
set stl=%f\ %(<%{b:gitstatus}>%)
