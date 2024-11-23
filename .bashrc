# Autostart Hyprland at Login
if [ -z "${WAYLAND_DISPLAY}" ] && [ "${XDG_VTNR}" -eq 1 ]; then
    exec Hyprland
fi

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

# Syntax highlighting (Bash equivalent using `bash-preexec`)
if [ -f /usr/share/bash-preexec/bash-preexec.sh ]; then
    . /usr/share/bash-preexec/bash-preexec.sh
fi

# Prompt customization
PS1='\[\e[32m\]\u@\h:\[\e[34m\]\w\[\e[0m\]\$ '

# Launch pfetch when opening a new terminal
if command -v pfetch &> /dev/null; then
    pfetch
fi
