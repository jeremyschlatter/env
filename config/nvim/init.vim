set nocompatible " Don't force VI compatibility when using vi

" Enable file type detection. Do this after Vundle calls.
filetype plugin indent on

let g:ctrlp_custom_ignore = 'node_modules'

" jeffkreeftmeijer/vim-numbertoggle
let g:NumberToggleTrigger = '<Leader>l'

" vim-go configuration
"let g:go_fmt_command = "goimports"
let g:go_fmt_command = "gofmt"
let g:go_fmt_fail_silently = 1
let g:go_template_autocreate = 0
"let g:go_metalinter_command = "--tests --min-confidence=.9"
"let g:go_metalinter_disabled="golint"
au FileType go nmap <Leader>t <Plug>(go-info)
au FileType go nmap <Leader>b :GoBuild<CR>

" In many terminal emulators the mouse works just fine, thus enable it.
if has('mouse')
  set mouse=a
endif

" Switch syntax highlighting on, when the terminal has colors.
if &t_Co > 2 || has("gui_running")
  syntax on
endif

" Make vim work with crontab, anything else that edits temp files
set backupskip=/tmp/*,/private/tmp/*

" Python tabs
set tabstop=4
set softtabstop=4
set shiftwidth=4
set expandtab

" More python configuration
let python_highlight_all = 1

" Wrapping for plaintext
set wrap
set linebreak
set nolist
set textwidth=0
set wrapmargin=0

autocmd FileType python set omnifunc=pythoncomplete#Complete

" don't connect to the X display
set cb="exclude:.*"

""" Filetype rules
highlight def link TooLongLine Error
augroup jeremyschlatter
  au!
" C/C++, sh, bash, javascript
  au BufRead,BufNewFile *.js,*.sh,*.bash,*.c,*.cc,*.cpp,*.h match TooLongLine /.\%>81v/
" Java
  au BufRead,BufNewFile *.java 2match TooLongLine /.\%>80v/
" Go
  au BufRead,BufNewFile *.go 2match Underlined /.\%101v\|.\%81v/
  au BufRead,BufNewFile *.go set noexpandtab tabstop=8 shiftwidth=8 softtabstop=8
  " Syntax highlighting sometimes breaks in long files. This setting help that. See
  "   http://vim.wikia.com/wiki/Fix_Syntax_Highlighting#MetaCosm_FixSyntaxHighlighting
  au BufRead,BufNewFile,BufWritePost *.go syntax sync minlines=800
" Python
  au BufRead,BufNewFile *.py,*.bazel,*.bzl 2match Underlined /.\%81v/
  au BufRead,BufNewFile *.py,*.bazel,*.bzl set et ts=4 sts=4 sw=4
" Javascript
  au BufRead,BufNewFile *.js,*.jsx,*.json,*.ts,*.yaml,*.sol,*.yml set tabstop=2 softtabstop=2 shiftwidth=2
  au BufRead,BufNewFile *.sol 2match TooLongLine /.\%>100v/
  au BufRead,BufNewFile *.sol set expandtab tabstop=4 softtabstop=4 shiftwidth=4
" Haskell
  au BufRead,BufNewFile *.hs 2match TooLongLine /.\%>101v/
  au BufRead,BufNewFile *.hs set expandtab tabstop=2 softtabstop=2 shiftwidth=2
" Bel
  au BufRead,BufNewFile *.bel set expandtab tabstop=2 softtabstop=2 shiftwidth=2 commentstring=;\ %s
augroup END

" Prettier
let g:prettier#autoformat = 0
autocmd BufWritePre *.js,*.css,*.scss,*.less Prettier

" Editing setup
set autoindent
set nomodeline            " Disable modeline which I don't use and is a potential security hole
set incsearch             " Search as you type
set whichwrap=bs~<>[]     " Let cursors, backspace, etc to move onto the next or previous line
call mkdir($HOME . "/.vim_runtime/bak", "p")
set backupdir=$HOME/.vim_runtime/bak  " Write backup files to ~/.vim_runtime/bak/*
set showmatch             " Show matches wile searching
set ruler                 " Show cursor position in the last line
set lazyredraw            " Don't redraw while executing macros
set number
set hls
set autowrite
set display+=lastline     " Display as much of the buffer as possible, even if the last line doesn't all fit
if has('persistent_undo')
  set undodir=$HOME/.vim_runtime/undodir
  set undofile
endif
set autoread              " Automatically read a file when it's changed externally
set showcmd               " Among other things, show incomplete commands andthe number of lines you have highlighted in visual mode
set ignorecase            " ignorecase + smartcase = disregard case when all
set smartcase             " the characters in the search string are lower case
set completeopt-=preview  " Don't pop up a preview window for completions.
set history=50            " keep 50 lines of command line history
set backspace=indent,eol,start
set formatoptions+=r      " Auto-continue comments. Credit: http://stackoverflow.com/a/952561

" Always show current filename. I find this useful when jumping around
" between definitions in code that sometimes lives in external libraries.
" h/t http://unix.stackexchange.com/a/111560
set laststatus=2

function! ToggleMouse()
  if &mouse == 'a'
    set mouse=
    echo "Mouse usage disabled"
  else
    set mouse=a
    echo "Mouse usage enabled"
  endif
endfunction

" Used by agda-vim
let maplocalleader = ","

let mapleader = ";"
nmap <silent> <leader>m :call ToggleMouse()<CR>
nmap <silent> <leader>h :split<CR>
nmap <silent> <leader>v :vsplit<CR>

" Sort a block of #include statements (really, any sequence of lines, bordered
" on top and bottom by empty lines).
nmap <silent> <leader>s "syy}kv?^$<CR>j!sort<CR>?<c-r>s<BS><CR>:noh<CR>:redraw<CR>:echo "Sorted"<CR>

" unmap commands that I only ever use unintentionally
map Q <ESC>
map U <ESC>

" shorten the commands to move between windows
if has('nvim')
  :tnoremap <c-h> <c-\><c-N><c-w>h
  :tnoremap <c-l> <c-\><c-N><c-w>l
  :tnoremap <c-j> <c-\><c-N><c-w>j
  :tnoremap <c-k> <c-\><c-N><c-w>k
  :inoremap <c-h> <c-\><c-N><c-w>h
  :inoremap <c-l> <c-\><c-N><c-w>l
  :inoremap <c-j> <c-\><c-N><c-w>j
  :inoremap <c-k> <c-\><c-N><c-w>k
endif
:nnoremap <c-h> <c-w>h
:nnoremap <c-l> <c-w>l
:nnoremap <c-j> <c-w>j
:nnoremap <c-k> <c-w>k

" toggle between .cc and .h
nmap <silent> <c-t> :A<CR>

imap <Nul> <Space>

" goodbye escape key
imap <c-@> <ESC>

" toggle comments
vmap <leader>c :s/^/\/\//<CR>:noh<CR>
vmap <leader>rc :s/^\/\//<CR>:noh<CR>

" put following arguments to a function on a new line
nmap K f,lxi<CR><ESC>

nmap <silent> ;n :noh<CR>
nmap ;l zo
nmap ;h zc
nmap ;i :GoImports<CR>

augroup autosourcevimrc
  au!
  au BufWritePost $MYVIMRC source $MYVIMRC
augroup END

" Tell vim to remember certain things when we exit
"  '10  :  marks will be remembered for up to 10 previously edited files
"  "100 :  will save up to 100 lines for each register
"  :20  :  up to 20 lines of command-line history will be remembered
"  %    :  saves and restores the buffer list
"  n... :  where to save the viminfo files
if !has('nvim')
    set viminfo='10,\"100,:20,%,n~/.viminfo
endif

" Main function that restores the cursor position and its autocmd so
" that it gets triggered:
function! ResCur()
  if line("'\"") <= line("$")
    normal! g`"
    return 1
  endif
endfunction

augroup resCur
  autocmd!
  autocmd BufWinEnter * call ResCur()
augroup END

" Close quickfix window when it is the only remaining window.
" Sometimes I want to quit vim while the quickfix window is open,
" so I type ':q<CR>'. By default, that just closes the main editor
" window, but not the quickfix window. With this it closes both.
"
" Credit: http://stackoverflow.com/a/7477056
aug QFClose
  au!
  au WinEnter * if winnr('$') == 1 && getbufvar(winbufnr(winnr()), "&buftype") == "quickfix"|q|endif
aug END

set encoding=utf-8
set termencoding=utf-8

" For webpack.
" https://webpack.github.io/docs/webpack-dev-server.html#working-with-editors-ides-supporting-safe-write
set backupcopy=yes

" Read current color (light vs dark), defaulting to dark
set background=dark
let s:color = readfile(expand('~/.config/colors'))
for s:colorLine in s:color
  let &background = s:colorLine
endfor
colorscheme solarized

if filereadable(expand('~/.local_vimrc'))
    source ~/.local_vimrc
endif

" Map escape to terminal escape sequence, as suggested in `:help terminal`
if has('nvim')
    :tnoremap <Esc> <C-\><C-n>
endif

" use jsx highlighting on .js files
" https://github.com/mxw/vim-jsx
let g:jsx_ext_required = 0

" fzf + rg
" http://owen.cymru/fzf-ripgrep-navigate-with-bash-faster-than-ever-before/
let g:rg_command = '
  \ rg --column --line-number --no-heading --fixed-strings --ignore-case --no-ignore --hidden --follow
  \ -g "*.{js,json,php,md,styl,jade,html,config,py,cpp,c,go,hs,rb,conf}"
  \ -g "!{.git,node_modules,vendor,build}/*" '

command! -bang -nargs=* F call fzf#vim#grep(g:rg_command .shellescape(<q-args>), 1, <bang>0)
nmap ;f :F<CR>

" Load all of the helptags now, after plugins have been loaded.
" All messages and errors will be ignored.
silent! helptags ALL

let g:org_heading_shade_leading_stars = 1
let g:org_indent = 1

let g:ycm_filetype_blacklist = {
    \ 'tagbar' : 1,
    \ 'qf' : 1,
    \ 'notes' : 1,
    \ 'markdown' : 1,
    \ 'unite' : 1,
    \ 'text' : 1,
    \ 'vimwiki' : 1,
    \ 'pandoc' : 1,
    \ 'infolog' : 1,
    \ 'mail' : 1,
    \ 'org': 1
    \}

" let g:LanguageClient_serverCommands = { 'haskell': ['hie-wrapper'] }
