require'leap'.set_default_keymaps()

require'nvim-treesitter.configs'.setup {
  highlight = { enable = true },
  indent = { enable = true },
}

require'tabs-vs-spaces'.setup {
  indentation = "auto",
  user_commands = true,
}

require'guess-indent'.setup {}

vim.filetype.add({
  extension = {
    ncl = 'nickel',
  }
})

vim.cmd([[
let g:ctrlp_custom_ignore = 'node_modules'

" jeffkreeftmeijer/vim-numbertoggle
let g:NumberToggleTrigger = '<Leader>l'

" vim-go configuration
let g:go_template_autocreate = 0
au FileType go nmap <Leader>t <Plug>(go-info)
au FileType go nmap <Leader>b :GoBuild<CR>

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
" Python
  au BufRead,BufNewFile *.py,*.bazel,*.bzl 2match Underlined /.\%81v/
" Solidity
  au BufRead,BufNewFile *.sol 2match TooLongLine /.\%>100v/
" Haskell
  au BufRead,BufNewFile *.hs 2match TooLongLine /.\%>101v/
" Bel
  au BufRead,BufNewFile *.bel set commentstring=;\ %s
" Dhall
  au BufRead,BufNewFile *.dhall set commentstring=--\ %s
" Coq
  au BufRead,BufNewFile *.mlg,*.v set commentstring=(*\ %s\ *)
" Nickel
  au BufRead,BufNewFile *.ncl setlocal commentstring=#\ %s
augroup END

" Editing setup
set whichwrap=bs~<>[]     " Let cursors, backspace, etc to move onto the next or previous line
set showmatch             " Show matches wile searching
set lazyredraw            " Don't redraw while executing macros
set number
set autowrite
set undofile
set ignorecase            " ignorecase + smartcase = disregard case when all
set smartcase             " the characters in the search string are lower case
set linebreak             " Wrapping for plaintext
set completeopt-=preview  " Don't pop up a preview window for completions.
set formatoptions+=r      " Auto-continue comments. Credit: http://stackoverflow.com/a/952561
set splitright " https://thoughtbot.com/blog/vim-splits-move-faster-and-more-naturally#more-natural-split-opening

function! ToggleMouse()
  if &mouse == 'nvi'
    set mouse=
    echo "Mouse usage disabled"
  else
    set mouse=nvi
    echo "Mouse usage enabled"
  endif
endfunction

" Used by agda-vim
let maplocalleader = ","

let mapleader = ";"
nmap <silent> <leader>m :call ToggleMouse()<CR>
nmap <silent> <leader>h :split<CR>
nmap <silent> <leader>v :vsplit<CR>

let g:camelcasemotion_key = ","

" Sort a block of #include statements (really, any sequence of lines, bordered
" on top by an empty line or beginning of file, and on bottom by an empty line).
nmap <silent> <leader>s "syy}kv{<RIGHT>0!sort<CR>?<c-r>s<BS><CR>:noh<CR>:redraw<CR>:echo "Sorted"<CR>

" unmap commands that I only ever use unintentionally
map Q <ESC>
map U <ESC>

" shorten the commands to move between windows
for c in ['h', 'l', 'j', 'k']
  for m in ['n', 't', 'i']
    execute m . "noremap \<c-" . c . "> \<c-\>\<c-N>\<c-w>" . c
  endfor
endfor

" put following arguments to a function on a new line
nmap K f,lxi<CR><ESC>

nmap <silent> ;n :noh<CR>
nmap ;l zo
nmap ;h zc
nmap ;i :GoImports<CR>

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

" Read current color (light vs dark), defaulting to dark
let s:color = readfile(expand('~/.config/colors'))
for s:colorLine in s:color
  let &background = s:colorLine
endfor
colorscheme NeoSolarized

" Map escape to terminal escape sequence, as suggested in `:help terminal`
tnoremap <Esc> <C-\><C-n>

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
]])
