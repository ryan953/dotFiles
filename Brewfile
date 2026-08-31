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
  personal_tap.cask_tokens.sort.each { |token| cask token }
end

# Other people's taps. Trust is granted per item, never to the whole tap, so a
# formula added to one of these later stays untrusted until I say otherwise.
tap "domt4/autoupdate", trusted: { commands: ["autoupdate"] }
tap "schpet/tap", trusted: { formulae: ["linear"] }
tap "terror/tap", trusted: { formulae: ["just-lsp"] }
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
brew "schpet/tap/linear"
brew "terror/tap/just-lsp"
brew "the_silver_searcher"
brew "tmux"
brew "umputun/apps/revdiff"
brew "vim"
brew "zx"

# Keep homebrew up to date
brew "terminal-notifier"

# NerdFonts
cask "font-meslo-lg-nerd-font"

# UI Programs
cask "agentsview"
cask "anki"
cask "brave-browser"
cask "brave-browser@beta"
cask "bitwarden"
brew "bitwarden-cli"
cask "boop"
cask "chromedriver"
cask "cursor"
cask "cyberduck"
cask "firefox"
cask "ghostty"
cask "gcloud-cli"
cask "maestral"
cask "obsidian"
cask "shottr"
cask "slack"
cask "sonos"
cask "spotify"
cask "tunnelblick"
cask "vlc"
cask "zoom"
