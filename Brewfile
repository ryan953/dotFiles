# My own taps: trusted wholesale, and everything published in them is installed.
# Adding a personal tap is one line here; adding a formula or cask to a tap that
# is already listed needs no change at all.
personal_taps = %w[
  ryan953/tap
]

personal_taps.each do |tap_name|
  tap tap_name, trusted: true

  personal_tap = ::Tap.fetch(tap_name)
  personal_tap.install unless personal_tap.installed?
  personal_tap.formula_names.sort.each { |formula| brew formula }
  personal_tap.cask_tokens.sort.each { |token| cask token, greedy: true }
end

# Other people's taps. Trust is granted per item, never to the whole tap, so a
# formula added to one of these later stays untrusted until I say otherwise.
tap "domt4/autoupdate", trusted: { commands: ["autoupdate"] }
tap "umputun/apps", trusted: { formulae: ["revdiff"] }

# Dependencies from install-zsh.sh
brew "ast-grep"
brew "bat"
brew "colima"
brew "direnv"
brew "docker"
brew "docker-compose"
brew "docker-credential-helper"
brew "eza"
brew "fd"
brew "fx" # JSON viewer
brew "git"
brew "git-delta"
brew "gh"
brew "htop"
brew "jq" # JSON processor
brew "pyenv"
brew "rnr" # Rename multiple files
brew "ripgrep"
brew "the_silver_searcher"
brew "tmux"
brew "umputun/apps/revdiff"
brew "vim"
brew "zx"

# Keep homebrew up to date
brew "terminal-notifier"

# Casks are marked greedy. Without this, any cask that sets auto_updates is 
# reported as current forever and never gets upgraded here.

# NerdFonts
cask "font-meslo-lg-nerd-font", greedy: true

# UI Programs
cask "agentsview", greedy: true
cask "anki", greedy: true
cask "brave-browser", greedy: true
cask "brave-browser@beta", greedy: true
cask "bitwarden", greedy: true
brew "bitwarden-cli"
cask "boop", greedy: true
cask "chromedriver", greedy: true
cask "cursor", greedy: true
cask "cyberduck", greedy: true
cask "firefox", greedy: true
cask "ghostty", greedy: true
cask "gcloud-cli", greedy: true
cask "maestral", greedy: true
cask "obsidian", greedy: true
cask "shottr", greedy: true
cask "slack", greedy: true
cask "sonos", greedy: true
cask "spotify", greedy: true
cask "tunnelblick", greedy: true
cask "vlc", greedy: true
cask "zoom", greedy: true
