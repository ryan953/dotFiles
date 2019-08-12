# Install on OSX

```bash
  curl -L https://github.com/ryan953/dotFiles/archive/master.zip > dotFiles.zip && \
    unzip -d ~ dotFiles.zip && \
    mv ~/dotFiles-master ~/.dotFiles && \
    rm dotFiles.zip && \
    ~/.dotFiles/install.sh
```


# More things to install

You might also want to add more things into your install.sh file. Here are some examples:

```
install_cask "docker"
install_cask "docker-toolbox"

install_brew "duck" "tig"
install_brew "dnsmasq" "nginx" "mysql" "redis" "sqlite"
install_brew "node" "node4-lts, "node5" "phantomjs"
install_brew "pcre"
install_brew "php55" "php55-mcrypt" "php56"
install_brew "python" "python3"
install_brew "gettext"

if install_cask "atom"; then
  install_brew "watchman"
  # also depends on `install_brew "flow"`
  # `amp install nuclide`
  # or save my APM modules and install from user-account
fi
```
