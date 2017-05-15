" Syntax highlighting
syntax on

" Text formatting
set tabstop=4
set expandtab

"
" vim-plug
" https://github.com/junegunn/vim-plug
"
call plug#begin('~/.vim/plugged')

" Swift
Plug 'keith/swift.vim'

" Using git URL
Plug 'https://github.com/junegunn/vim-github-dashboard.git'

" Add plugins to &runtimepath
call plug#end()
" END: vim-plug

"
" Powerline
" https://computers.tutsplus.com/tutorials/getting-spiffy-with-powerline--cms-20740#highlighter_916896
"
" pip show powerline-status
set runtimepath+=/usr/local/lib/python2.7/site-packages/bindings/vim

" These lines setup the environment to show graphics and colors correctly.
set nocompatible
set t_Co=256

let g:minBufExplForceSyntaxEnable = 1
python from powerline.vim import setup as powerline_setup
python powerline_setup()
python del powerline_setup

if ! has('gui_running')
   set ttimeoutlen=10
   augroup FastEscape
      autocmd!
      au InsertEnter * set timeoutlen=0
      au InsertLeave * set timeoutlen=1000
   augroup END
endif

set laststatus=2 " Always display the statusline in all windows
set guifont=Inconsolata\ for\ Powerline:h14
set noshowmode " Hide the default mode text (e.g. -- INSERT -- below the statusline)
" END: Powerline

