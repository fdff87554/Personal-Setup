#!/bin/sh
git config --global user.email "me@crazyfirelee.tw"
git config --global user.name "Crazyfire Lee"
git config --global color.ui true
git config --global core.editor "vim"
git config --global alias.co commit
git config --global alias.lg "log --color --graph --all --pretty=format:'%Cred%h%Creset -%C(yellow)%d%Creset %s %Cgreen(%cr) %C(bold blue)<%an>%Creset' --abbrev-commit --"
git config --global alias.supdate "submodule update --init --recursive"
git config --global alias.supdate-remote "submodule update --remote --rebase"
git config --global alias.sstatus "submodule status"
