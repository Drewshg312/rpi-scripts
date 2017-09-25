" Configuration for Bash Editing:
setlocal tabstop=4              " a tab is four spaces
setlocal softtabstop=4          " delete tabs as one keystroke
setlocal shiftwidth=4           " number of spaces to use for autoindenting

setlocal smarttab               " insert tabs on the start of a line according to shiftwidth, not tabstop
setlocal smartindent            " adds indents to lines between { }. Removes indents when first symbol is '#'
setlocal autoindent             " always setlocal autoindenting on
setlocal copyindent             " copy the previous indentation on autoindenting
setlocal expandtab              " do not convert tabs to spaces

setlocal showmatch              " setlocal show matching parenthesis

setlocal nowrap                 " show long lines as one line (scroll horisontally to see entire line)

setlocal formatoptions+=tcroql  " autocomment for '#, //, /**/' comments (does not work for .vim files like .vimrc)

setlocal list listchars=tab:▸·,trail:·,precedes:←,extends:→,nbsp:‡ ",eol:§

