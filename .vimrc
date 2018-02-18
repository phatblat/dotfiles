" Syntax highlighting
syntax on

" Text formatting
set tabstop=4
set expandtab

"-------------------------------------------------------------------------------
"
" Example config
" https://pchm.co/posts/from-textmate-to-vim
"
"-------------------------------------------------------------------------------

set nocompatible                " choose no compatibility with legacy vi
syntax enable
set encoding=utf-8
set showcmd                     " display incomplete commands
filetype plugin indent on       " load file type plugins + indentation

set autowrite     " Automatically :write before running commands

set backspace=2   " Backspace deletes like most programs in insert mode
set nobackup
set nowritebackup
set noswapfile    " http://robots.thoughtbot.com/post/18739402579/global-gitignore#comment-458413287
set history=50
set ruler         " show the cursor position all the time
set showcmd       " display incomplete commands
set laststatus=2  " Always display the status line
set timeout timeoutlen=1000 ttimeoutlen=101 " fast insert with "O"

set number
set relativenumber

" Auto-reload buffers when file changed on disk
set autoread

" Make it obvious where 90 characters is
set textwidth=90
set colorcolumn=+1

"" Whitespace
set nowrap                      " don't wrap lines
set expandtab                   " use spaces, not tabs (optional)
set backspace=indent,eol,start  " backspace through everything in insert mode

"" Searching
set hlsearch                    " highlight matches
set incsearch                   " incremental searching
set ignorecase                  " searches are case insensitive...
set smartcase                   " ... unless they contain at least one capital letter

" Mouse
"set mouse=a

let mapleader=","

" Get off my lawn
nnoremap <Left> :echoe "Use h"<CR>
nnoremap <Right> :echoe "Use l"<CR>
nnoremap <Up> :echoe "Use k"<CR>
nnoremap <Down> :echoe "Use j"<CR>

" Switch between files by hitting ,, twice
nnoremap <leader><leader> <c-^>

" Clear search results by hitting Enter
nnoremap <CR> :noh<CR><CR>

" Open new split panes to right and bottom (more natural than Vim's default)
set splitbelow
set splitright

" easier navigation between split windows
nnoremap <c-j> <c-w>j
nnoremap <c-k> <c-w>k
nnoremap <c-h> <c-w>h
nnoremap <c-l> <c-w>l

" Tab navigation like Firefox.
nnoremap <C-S-tab> :tabprevious<CR>
nnoremap <C-tab>   :tabnext<CR>
nnoremap <C-t>     :tabnew<CR>
inoremap <C-S-tab> <Esc>:tabprevious<CR>i
inoremap <C-tab>   <Esc>:tabnext<CR>i
inoremap <C-t>     <Esc>:tabnew<CR>

nnoremap <C-Insert> :tabnew<CR>
nnoremap <C-Delete> :tabclose<CR>

nnoremap th  :tabfirst<CR>
nnoremap tj  :tabnext<CR>
nnoremap tk  :tabprev<CR>
nnoremap tl  :tablast<CR>
nnoremap tt  :tabedit<Space>
nnoremap tn  :tabnext<Space>
nnoremap tm  :tabm<Space>
nnoremap td  :tabclose<CR>

" Next/previous tab
nnoremap H gT
nnoremap L gt

" Always open files in new tabs
autocmd VimEnter * tab all
autocmd BufAdd * exe 'tablast | tabe "' . expand( "<afile") .'"'

" unmap ex mode: 'Type visual to go into Normal mode.'
nnoremap Q <nop>

" paste lines from unnamed register and fix indentation
nmap <leader>p "*pV`]=
nmap <leader>P "*PV`]=

" copy to system clipboard with <leader>y
map <leader>y "*y

" copy current file path to system clipboard
nmap <leader>cs :let @*=expand("%")<CR>
" copy current (full) file path to system clipboard
nmap <leader>cl :let @*=expand("%:p")<CR>

" YouCompleteMe
" ^P	basic tab completion, pulling from a variety of sources
" ^N	the same as ^P but backward
" ^X ^L	whole line completion
" ^X ^O	syntax-aware omnicompletion

inoremap <Tab> <C-P>

set complete=.,b,u,]
set wildmode=longest,list:longest
set completeopt=menu,preview

" display trailing whitespace
set list listchars=tab:»·,trail:·,nbsp:·

" remove traling whitespace on save
" autocmd FileType rb,erb,html,css,js,coffee,sass,haml autocmd BufWritePre <buffer> :%s/\s\+$//e

autocmd BufWritePre * :%s/\s\+$//e " the command above doesn't seem to work

" no beeps!
set visualbell
set t_vb=


"-------------------------------------------------------------------------------
"
" vim-plug
" https://github.com/junegunn/vim-plug
"
"-------------------------------------------------------------------------------
call plug#begin('~/.vim/plugged')

" Swift
Plug 'keith/swift.vim'

" Using git URL
Plug 'https://github.com/junegunn/vim-github-dashboard.git'

" Add plugins to &runtimepath
call plug#end()
" END: vim-plug


"-------------------------------------------------------------------------------
"
" Vundle
" https://github.com/VundleVim/Vundle.vim#about
"
"-------------------------------------------------------------------------------
set nocompatible              " be iMproved, required
filetype off                  " required

" set the runtime path to include Vundle and initialize
set runtimepath+=~/.vim/bundle/Vundle.vim
call vundle#begin()

" let Vundle manage Vundle, required
Plugin 'VundleVim/Vundle.vim'
Plugin 'Valloric/YouCompleteMe'

" All of your Plugins must be added before the following line
call vundle#end()            " required
filetype plugin indent on    " required
" To ignore plugin indent changes, instead use:
"filetype plugin on

set shell=/bin/bash     " for fish shell

" Brief help
" :PluginList       - lists configured plugins
" :PluginInstall    - installs plugins; append `!` to update or just :PluginUpdate
" :PluginSearch foo - searches for foo; append `!` to refresh local cache
" :PluginClean      - confirms removal of unused plugins; append `!` to auto-approve removal
"
" see :h vundle for more details or wiki for FAQ
" END: Vundle


"-------------------------------------------------------------------------------
"
" Powerline
" https://computers.tutsplus.com/tutorials/getting-spiffy-with-powerline--cms-20740#highlighter_916896
"
"-------------------------------------------------------------------------------
" pip show powerline-status
set runtimepath+=/usr/local/lib/python3.6/site-packages/powerline/bindings/vim

" These lines setup the environment to show graphics and colors correctly.
set nocompatible
set t_Co=256

let g:minBufExplForceSyntaxEnable = 1

" FIXME: powerline is working despite the broken python lines below
" E319: Sorry, the command is not available in this version: python3
"let g:pymode_python = 'python3'

" https://powerline.readthedocs.io/en/latest/usage/other.html#vim-statusline
"python3 from powerline.vim import setup as powerline_setup
"python3 powerline_setup()
"python3 del powerline_setup

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

