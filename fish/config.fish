source /usr/share/cachyos-fish-config/cachyos-config.fish
set -gx RICE_HOME "$HOME/.config"

# Override CachyOS default fastfetch greeting
function fish_greeting
end

# nvm - using bass to source bash script
function nvm
    bass source /usr/share/nvm/init-nvm.sh \; nvm $argv
end

set -gx PATH $HOME/.local/share/fnm $PATH
fnm env --use-on-cd | source

