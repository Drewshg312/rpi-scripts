# Ultimate Vim Setup

  [![Ansible Galaxy](http://img.shields.io/badge/ansible--galaxy-vim-blue.svg)](https://galaxy.ansible.com/list#/roles/6323)

  This role is forked from [SamyRoad/ansible-vim](https://github.com/SamyRoad/ansible-vim) and modified for my needs.

  The role is compatible with Debian/Ubuntu

  The role does the following:
    - Removes vim-tiny
    - Installs vim-nox (needed for Powerline plugin)
    - Sets EDITOR environment variable to use vim-nox
    - Installs [Vundle](https://github.com/VundleVim/Vundle.vim) plugin manager for vim
    - Installs git (as a dependency for Vundle installation)
    - Installs set of Plugins defined in default/main.yml
    - Configures vim (system-wide or per-user) as defined in default/main.yml (using my custom configuration)
    - Installs [Solarized](https://github.com/altercation/vim-colors-solarized#important-note-for-terminal-users) and
      customized [Mustang](https://hcalves.deviantart.com/art/Mustang-Vim-Colorscheme-98974484) colorschemes.

  IT IS NOT A GOOD IDEA to install [Emoji](https://github.com/junegunn/vim-emoji) plugin both system-wide and per user.
  Vim sources both system-wide and user's vimrc files and complains about duplicated emoji command.
  This will also cause command 'vim +PluginInstall +qall' to hang or fail.

  If installing current role system-wide and per user, comment 'junegunn/vim-emoji' in default/main.yaml for system
  installation and uncomment it for per-user installation.

## Use case #1: install for shared usage

  You want to install a custom vim settings and plugins in your remote server. This config is shared between all server
  users, but customized settings for a single user is allowed if you want.

  Set `vim_env` variable to `system` in your playbook.

  The common config is placed in `/etc/vim/vimrc.local` (for settings) and `/etc/vim/vimrc.bundles` (for plugins).

  If you need to overwrite any setting or install new plugins for a selected user, you need to put your settings in
  these files: `~/.vimrc.local` and `~/.vimrc.bundles.local`

  **Important**: by default, plugins are installed for `root` user. In all other users you have to install plugins
  manually with command `vim +PluginInstall`.

  Refer to [Vundle documentation](https://github.com/VundleVim/Vundle.vim) for plugin management.


## Use case #2: install for a single user

  You want to use this ansible role to provision your own laptop and just want a customized vim for your user. All your
  config lives in your `$HOME` path, just like regular vim install.

  Set `vim_env` variable to `user` in your playbook and set `vim_users` variable with a list of users to install vim.

  The common config is placed in `~/vimrc` (for settings) and `~/vimrc.bundles` (for plugins).

  If you need to overwrite any setting or install new plugins for a selected user, you need to put your settings in
  these files: `~/.vimrc.local` and `~/.vimrc.bundles.local`

  Refer to [Vundle documentation](https://github.com/VundleVim/Vundle.vim) for plugin management.


## Requirements

  Ansible  1.9 or greater

## Role Variables

| Name                 | Description |
| ----                 | ----------- |
| `vim_env`            | Where to install vim: system or user.<br/> If you install it system-wide, all users will use your default configuration. |
| `vim_users`          | List of users to install vim. Use it in conjunction with `vim_env`. |
| `vim_plugins`        | List of vim plugins to install. Use [Vundle](https://github.com/gmarik/Vundle.vim) format. |
| `vim_vundle_version` | Vundle version to install. |

## Dependencies

  Git

## License

  MIT

## Author Information

  Moisés Maciá <mmacia@gmail.com>
