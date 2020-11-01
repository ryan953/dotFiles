set nocompatible           " be iMproved, required for Vundle
filetype off               " required for Vundle, will be turned on later

set rtp+=~/.vim/bundle/Vundle.vim  " required for Vundle

" Vundle help:
" :PluginList       - lists configured plugins
" :PluginInstall    - installs plugins; append `!` to update or just :PluginUpdate
"                   - Or call `vim +PluginInstall +qall` from the command line
" :PluginSearch foo - searches for foo; append `!` to refresh local cache
" :PluginClean      - confirms removal of unused plugins; append `!` to auto-approve removal
call vundle#begin()
Plugin 'VundleVim/Vundle.vim' " Vundle manages itself

Plugin 'vim-airline/vim-airline'
Plugin 'vim-airline/vim-airline-themes'
Plugin 'https://github.com/joshdick/onedark.vim'

" Disable tmuxline because the theme is incompatible with auto-setting colors on mode change
" Plugin 'edkolev/tmuxline.vim'

Plugin 'christoomey/vim-tmux-navigator'

Plugin 'airblade/vim-gitgutter'

Plugin 'https://github.com/ctrlpvim/ctrlp.vim.git'

Plugin 'preservim/nerdcommenter'

"""
" After adding a new plugin, run `:PluginInstall`
"""
call vundle#end()

filetype plugin indent on



""" Basics
set cursorline  " highlight current line
set number      " Show line numbers
set ruler       " Show row and column ruler information
set showmatch   " Highlight matching brace
set wildmenu    " visual autocomplete for command menu

set undolevels=1000             " Number of undo levels
set backspace=indent,eol,start  " Backspace behaviour

set foldmethod=indent " fold based on indent level
set foldlevel=10      " fold the 10th indent

set hlsearch    " Highlight all search results
set ignorecase  " Always case-insensitive
set incsearch   " Searches for strings incrementally
set smartcase   " Enable smart-case search

set updatetime=100

" Disable backups and .swp files.
set nobackup
set noswapfile
set nowritebackup

" Indentation settings.
set autoindent
set expandtab
set shiftwidth=4
set softtabstop=4
set tabstop=4

" Use system clipboard.
set clipboard=unnamedplus

set mouse=a " Enable mouse scrorling and other behaviors

" Don't complain about unsaved files when switching buffers.
set hidden
" set nohidden


""" Color Settings

" Airline Settings
let g:airline_powerline_fonts = 0
let g:airline_theme = 'onedark'
let g:airline#extensions#tabline#enabled = 1
let g:airline#extensions#tabline#formatter = 'unique_tail_improved'

"Use 24-bit (true-color) mode in Vim/Neovim when outside tmux.
"If you're using tmux version 2.2 or later, you can remove the outermost $TMUX check and use tmux's 24-bit color support
"(see < http://sunaku.github.io/tmux-24bit-color.html#usage > for more information.)
if (empty($TMUX))
  if (has("nvim"))
    "For Neovim 0.1.3 and 0.1.4 < https://github.com/neovim/neovim/pull/2198 >
    let $NVIM_TUI_ENABLE_TRUE_COLOR=1
  endif
  "For Neovim > 0.1.5 and Vim > patch 7.4.1799 < https://github.com/vim/vim/commit/61be73bb0f965a895bfb064ea3e55476ac175162 >
  "Based on Vim patch 7.4.1770 (`guicolors` option) < https://github.com/vim/vim/commit/8a633e3427b47286869aa4b96f2bfc1fe65b25cd >
  " < https://github.com/neovim/neovim/wiki/Following-HEAD#20160511 >
  if (has("termguicolors"))
    set termguicolors
  endif
endif

" Disable custom editor background when running in a terminal, let terminal color show through
if (has("autocmd") && !has("gui_running"))
  augroup colorset
    autocmd!
    let s:white = { "gui": "#ABB2BF", "cterm": "145", "cterm16" : "7" }
    autocmd ColorScheme * call onedark#set_highlight("Normal", { "fg": s:white }) " `bg` will not be styled since there is no `bg` setting
  augroup END
endif

" Vertical bar between splits that's connected top + bottom
set fillchars+=vert:\▏
syntax on
set background=dark
colorscheme onedark

" Trim trailing whitespace in the file.
command TrimWhitespace %s/\s\+$//e

" Map leader key.
let mapleader = "\\"



""" Bindings
" The optional `nore` segment means that the RHS is not itself a mapped sequence.
" :[nore]map  => normal mode, visual + select, operator-pending
" :n[nore]map => normal mode
" :v[nore]map => visual + select
" :o[nore]map => operator-pending


""" Within a pane
nnoremap <Leader>ve :e $MYVIMRC<cr>  " Edit .vimrc file
nnoremap <Leader>vr :so $MYVIMRC<cr> " Reload .vimrc file
nnoremap <Leader>rr :redraw!<cr>     " Redraw screen to fix visual problems
nnoremap <Leader>w :w<CR>            " Write a file.

" Absolute movement for word-wrapped lines.
nnoremap j gj
nnoremap k gk

""" Buffers & Splits
nnoremap <leader>T :enew<cr> " To open a new empty buffer
nnoremap <leader>bq :bp <BAR> bd #<CR> " Close buffer and move to previous

set splitbelow
set splitright

let g:tmux_navigator_no_mappings = 1
" Vim Style split navigation
nnoremap <C-A>h :TmuxNavigateLeft<cr>     " Move to split Left
nnoremap <C-A>j :TmuxNavigateDown<cr>     " Move to split Down
nnoremap <C-A>k :TmuxNavigateUp<cr>       " Move to split Up
nnoremap <C-A>l :TmuxNavigateRight<cr>    " Move to split Right
nnoremap <C-A>\ :TmuxNavigatePrevious<cr> " Move to the previous split
" Arrow Style split navigation
nnoremap <C-A><Left>  :TmuxNavigateLeft<cr>  " Move to split Left
nnoremap <C-A><Down>  :TmuxNavigateDown<cr>  " Move to split Down
nnoremap <C-A><Up>    :TmuxNavigateUp<cr>    " Move to split Up
nnoremap <C-A><Right> :TmuxNavigateRight<cr> " Move to split Right

" Vim Style split resizing
nnoremap <C-A>H <C-w>5< " Make split narrower
nnoremap <C-A>J <C-w>5+ " Make split shorter
nnoremap <C-A>K <C-w>5- " Make split taller
nnoremap <C-A>L <C-w>5> " Make split wider:
" Arrow style split resizing
nnoremap <C-A><S-Left>  <C-w>5< " Make split narrower
nnoremap <C-A><S-Up>    <C-w>5- " Make split shorter
nnoremap <C-A><S-Down>  <C-w>5+ " Make split taller
nnoremap <C-A><S-Right> <C-w>5> " Make split wider:


""" Plugins

" GitGutter
let g:gitgutter_map_keys = 0

" CtrlP
let g:ctrlp_custom_ignore = {
  \ 'dir':  '\v[\/]\.(git|hg|svn)$',
  \ 'file': '\v\.(exe|so|dll)$',
  \ 'link': 'some_bad_symbolic_links',
  \ }
" let g:ctrlp_user_command = 'find %s -type f' " TODO: improve this with fzf

" NERDCommenter
let g:NERDCreateDefaultMappings = 0
nmap <C-z> <Plug>NERDCommenterToggle
vmap <C-z> <Plug>NERDCommenterToggle


nnoremap <Leader>] <C-]>            " Jump to ctags tag definition.
nnoremap <Leader>p :CtrlP<cr>       " Fuzzy complete for files.
nnoremap <Leader>t :CtrlPTag<cr>    " Fuzzy complete for tags.
