# Git Cheatsheet

## Base Setup

* `sudo sh git.sh`
    * set username -  `git config --global user.name`
    * set email - `git config --global user.email`
    * open coler ui - `git config --global color.ui true`
    * set editor to vim - `git config --global core.editor "vim"`

## Remote Settings

* Add remote repo to local repository - `git add remote origin <repo_url>` 
    * e.g. `git remote add github git@github.com:fdff87554/Personal-Setup.git`
* Show remote repositories - `git remote`
* Show all repositories fetch & push - `git remote -v`
* Show remote repositories details - `git remote show <tag>`
    * e.g. `git remote show origin`
* Rename remote repositories - `git remote rename <old_name> <new_name>`
    * e.g. `git remote rename origin github`
* Remove remote repositories - `git remote rm <repo_name>`
    * e.g. `git remote rm github`


