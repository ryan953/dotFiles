# Testing in Ubuntu

```bash
$ docker build -t ubuntu-zsh .
$ docker run -it --rm -v $(pwd):/home/ryan953/dotFiles ubuntu-zsh
```

Then in the image run:
```bash
$ ~/dotFiles/bootstrap.sh; ~/dotFiles/install-zsh.sh && /bin/zsh
```
# Install
```bash
$ bootstrap.sh && /bin/zsh
```

# iTerm colors:
```bash
curl https://raw.githubusercontent.com/ryan953/dotFiles/main/iterm/ryan953.itermcolors > ~/Documents/ryan953.itermcolors
```

Then import via the iTerm Settings->Profile->Colors panel

# Update Antigen
```bash
$ curl -L git.io/antigen > ~/.dotFiles/templates/.antigen.zsh
$ antigen update
```

