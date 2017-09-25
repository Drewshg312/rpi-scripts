let g:tagbar_type_yaml = {
    \ 'ctagstype' : 'yaml',
    \ 'kinds' : [
        \ 't:tasks'
    \ ],
    \ 'sort' : 0
\ }

setlocal tabstop=2              " a tab is four spaces
setlocal softtabstop=2          " delete tabs as one keystroke
setlocal shiftwidth=2           " number of spaces to use for autoindenting

setlocal smarttab               " insert tabs on the start of a line according to shiftwidth, not tabstop
setlocal nosmartindent          " leaves comments '#' on the same indentation level
setlocal autoindent             " always set autoindenting on
setlocal nocopyindent           " copy the previous indentation on autoindenting
setlocal expandtab              " convert tabs to spaces

setlocal formatoptions+=tcroql  " autocomment for '#, //, /**/' comments (does not work for .vim files like .vimrc)

setlocal list listchars=tab:▸·,trail:·,precedes:←,extends:→,nbsp:‡ ",eol:§

" Make autocomments work properly and prevent indenting current line when pressing Enter:
filetype plugin indent off

" If filetype plugin indent has to be used, then use following function
" to prevent filetype indent plugin indenting current line when pressing Enter
" This must go after 'filetype plugin indent on'
"augroup overrideftplugins
"    au!
"    au FileType * set cinkeys= indentkeys=
"augroup END
" This must be added in .vim/after/ftplugin/yaml.vim, but removed from
" .vim/after/ftplugin/ansible.vim

