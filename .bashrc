# Autostart Hyprland at Login
if [ -z "${WAYLAND_DISPLAY}" ] && [ "${XDG_VTNR}" -eq 1 ]; then
    exec Hyprland
fi

# Aliases
alias q='exit'
alias ..='cd ..'
alias ls='exa -l -F --icons --hyperlink'
alias l='ls -l'
alias la='ls -a'
alias lla='ls -la'
alias t='tree'
alias rm='rm -v'
alias open='xdg-open'

alias v='nvim'
alias vi='nvim'
alias vim='nvim'
alias nv='neovide'

alias gs='git status'
alias ga='git add -A'
alias gc='git commit'
alias gpll='git pull'
alias gpsh='git push'
alias gd='git diff'
alias gl='git log --stat --graph --decorate --oneline'

alias pu='sudo pacman -Syu'
alias pi='sudo pacman -S'
alias pr='sudo pacman -Rsu'
alias pq='sudo pacman -Qe'
alias autoclean='sudo pacman -Qtdq | sudo pacman -Rns - && yay -Sc'

alias cr='cargo run'
alias cb='cargo build'
alias ct='cargo test'
alias clippy='cargo clippy'

alias lock='swaylock'
alias standby='systemctl suspend'

alias ff='fastfetch'
alias b='bat'
alias rr='ranger --choosedir=$HOME/.rangerdir; LASTDIR=`cat $HOME/.rangerdir`; cd "$LASTDIR"'
alias z='zathura'

# Colored output
#alias ls='ls -laGH --color=auto'
alias diff='diff --color=auto'
alias grep='grep --color=auto'
alias ip='ip --color=auto'

# PATH for dependencies and local binaries
export PATH="$HOME/.local/bin:$PATH"
export PATH="$HOME/.cargo/bin:$PATH"
export PATH="$PATH:/usr/local/bin:/usr/bin:/bin"

# XDG user directories
export XDG_CONFIG_HOME="$HOME/.config"
export XDG_CACHE_HOME="$HOME/.cache"
export XDG_DATA_HOME="$HOME/.local/share"

# Colored output for commands
export LESS='-R --use-color -Dd+r$Du+b'
export MANPAGER='less -R --use-color -Dd+r -Du+b'
export BAT_THEME='Catppuccin Latte'

# Setting Default Editor
export EDITOR='nvim'
export VISUAL='nvim'

# History settings
export HISTFILE=~/.bash_history
export HISTSIZE=1000
export HISTFILESIZE=2000
shopt -s histappend  # Append to history file, don't overwrite
shopt -s cmdhist     # Save multi-line commands as one entry

# Autosuggestions (Bash equivalent)
if [ -f /usr/share/bash-completion/bash_completion ]; then
  . /usr/share/bash-completion/bash_completion
fi

# Syntax highlighting
if [ -f "$HOME/.bash-preexec/bash-preexec.sh" ]; then
  . "$HOME/.bash-preexec/bash-preexec.sh"
fi

# Prompt customization
PS1='\[\e[32m\]\u@\h:\[\e[34m\]\w\[\e[0m\]\$ '

# Launch pfetch when opening a new terminal
if command -v pfetch &> /dev/null; then
  pfetch
fi
