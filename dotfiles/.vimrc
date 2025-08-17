# Vim Configuration for Development
set nocompatible              " Disable Vi compatibility
syntax on                     " Enable syntax highlighting
filetype plugin indent on    " Enable filetype detection

" Basic Settings
set number                    " Show line numbers
set relativenumber           " Show relative line numbers
set cursorline               " Highlight current line
set showmatch                " Show matching brackets
set ignorecase               " Ignore case in search
set smartcase                " Smart case sensitivity
set hlsearch                 " Highlight search results
set incsearch                " Incremental search
set autoindent               " Auto indentation
set smartindent              " Smart indentation
set expandtab                " Use spaces instead of tabs
set tabstop=4                " Tab width
set shiftwidth=4             " Shift width
set softtabstop=4            " Soft tab stop
set wrap                     " Wrap long lines
set linebreak                " Break lines at word boundaries
set scrolloff=8              " Keep 8 lines above/below cursor
set sidescrolloff=8          " Keep 8 columns left/right of cursor
set mouse=a                  " Enable mouse support
set clipboard=unnamedplus    " Use system clipboard
set hidden                   " Allow hidden buffers
set backup                   " Enable backup
set backupdir=~/.vim/backup  " Backup directory
set directory=~/.vim/swap    " Swap directory
set undofile                 " Persistent undo
set undodir=~/.vim/undo      " Undo directory

" Create directories if they don't exist
if !isdirectory($HOME."/.vim/backup")
    call mkdir($HOME."/.vim/backup", "p", 0700)
endif
if !isdirectory($HOME."/.vim/swap")
    call mkdir($HOME."/.vim/swap", "p", 0700)
endif
if !isdirectory($HOME."/.vim/undo")
    call mkdir($HOME."/.vim/undo", "p", 0700)
endif

" Key mappings
let mapleader = ","          " Set leader key
nnoremap <leader>w :w<CR>    " Quick save
nnoremap <leader>q :q<CR>    " Quick quit
nnoremap <leader>x :x<CR>    " Quick save and quit

" Clear search highlighting
nnoremap <leader>/ :nohlsearch<CR>

" Better navigation between windows
nnoremap <C-h> <C-w>h
nnoremap <C-j> <C-w>j
nnoremap <C-k> <C-w>k
nnoremap <C-l> <C-w>l

" File type specific settings
autocmd FileType python setlocal tabstop=4 shiftwidth=4 softtabstop=4
autocmd FileType javascript setlocal tabstop=2 shiftwidth=2 softtabstop=2
autocmd FileType html setlocal tabstop=2 shiftwidth=2 softtabstop=2
autocmd FileType css setlocal tabstop=2 shiftwidth=2 softtabstop=2
autocmd FileType yaml setlocal tabstop=2 shiftwidth=2 softtabstop=2
autocmd FileType json setlocal tabstop=2 shiftwidth=2 softtabstop=2

" Status line
set laststatus=2
set statusline=%F%m%r%h%w\ [%l,%v][%p%%]\ %{strftime('%H:%M')}

" Colors
colorscheme default
set background=dark
