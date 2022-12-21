# Lima-VM

## Usage

```bash=
# install lima
brew install lima
# build vm
limactl start --name ubuntu-22_04-amd64 https://raw.githubusercontent.com/fdff87554/Personal-Setup/main/mac-os/lima-vm/configs/ubuntu-22_04.yaml
# enter shell
limactl shell ubuntu-22_04-amd64
# stop vm
limactl stop ubuntu-22_04-amd64
# remove vm
limactl delete ubuntu-22_04-amd64
```
