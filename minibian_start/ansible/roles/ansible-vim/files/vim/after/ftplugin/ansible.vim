let g:tagbar_type_ansible = {
    \ 'ctagstype' : 'ansible',
    \ 'kinds' : [
        \ 't:tasks'
    \ ],
    \ 'sort' : 0
\ }

setlocal tabstop=2              " a tab is four spaces
setlocal softtabstop=2          " delete tabs as one keystroke
setlocal shiftwidth=2           " number of spaces to use for autoindenting

setlocal expandtab              " convert tabs to spaces
setlocal smarttab               " insert tabs on the start of a line according to shiftwidth, not tabstop
setlocal nosmartindent          " leaves comments '#' on the same indentation level
setlocal autoindent             " always set autoindenting on
setlocal nocopyindent           " copy the previous indentation on autoindenting

setlocal formatoptions+=tcroql  " autocomment for '#, //, /**/' comments (does not work for .vim files like .vimrc)

setlocal list listchars=tab:▸·,trail:·,precedes:←,extends:→,nbsp:‡ ",eol:§

