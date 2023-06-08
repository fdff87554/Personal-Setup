# Quick Server Setup - 快速伺服器設定

- This is a script for quickly setting up a server for base development usage.

## Usage

- Run the script with root privilege.
- For Ubuntu / Debian / ..., run the following command to install `curl` first.
  ```bash
  # update apt package list
  sudo apt update
  # install curl
  sudo apt install curl -y
  ```
- Get the script and run it.
  ```bash
  # get the script
  curl -L https://raw.githubusercontent.com/fdff87554/Personal-Setup/main/quick-server-setup/quick-server-setup.sh -o ~/quick-server-setup.sh
  # run the script
  sudo sh quick-server-setup.sh
  ```
- After the script is done, you can check the following items:
  - [ ] `git` is installed.
  - [ ] `vim` is installed.
  - [ ] `tmux` is installed.
  - [ ] `ssh-server` is installed.
