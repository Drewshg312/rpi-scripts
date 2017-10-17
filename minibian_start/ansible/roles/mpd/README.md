ansible-mpd-mpc-ncmpcpp
=========

The role installs MPD, MPC and NCMPCPP on OSX and Linux Systems


Requirements
------------

Tested on minibian (debian jessie, raspbian), should also work on Fedora

Role Variables
--------------

For installing only MPD set mpd_install_mpc and mpd_install_ncmpcpp to 'False'

For installing only ncmpcpp (or mpc) set the corresponding variable to 'True' and
run the playbook with role specifying tags:
    `ansible-playbook ./playbook.yml --tags 'mpc,ncmpcpp'`


Dependencies
------------

A list of other roles hosted on Galaxy should go here, plus any details in regards to parameters that may need to be set for other roles, or variables that are used from other roles.

Example Playbook
----------------

Including an example of how to use your role (for instance, with variables passed in as parameters) is always nice for users too:

    - hosts: servers
      roles:
         - { role: username.rolename, x: 42 }

License
-------

MIT

Author Information
------------------
Andrew Shagayev
drewshg@gmail.com
