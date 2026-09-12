# Interactive development shell.
[[ -o interactive ]] || return
export EDITOR=nvim VISUAL=nvim
export LESS='-R'
typeset -U path
path=($HOME/.local/bin $path)
HISTFILE=$HOME/.zsh_history
HISTSIZE=50000
SAVEHIST=50000
setopt APPEND_HISTORY SHARE_HISTORY HIST_IGNORE_ALL_DUPS HIST_IGNORE_SPACE HIST_REDUCE_BLANKS
setopt AUTO_CD INTERACTIVE_COMMENTS NO_BEEP
bindkey -e
zmodload zsh/complist
autoload -Uz compinit
compinit
zstyle ':completion:*' menu select
zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}'
zstyle ':completion:*' list-colors ${(s.:.)LS_COLORS}
[[ -r /usr/share/fzf/key-bindings.zsh ]] && source /usr/share/fzf/key-bindings.zsh
[[ -r /usr/share/fzf/completion.zsh ]] && source /usr/share/fzf/completion.zsh
export FZF_DEFAULT_COMMAND='fd --type f --hidden --exclude .git'
export FZF_DEFAULT_OPTS='--height=45% --layout=reverse --border=rounded --color=bg:#000000,bg+:#202020,fg:#cccccc,fg+:#ffffff,hl:#91b4d5,hl+:#91b4d5,border:#444444,pointer:#a3c99c'
export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
export FZF_ALT_C_COMMAND='fd --type d --hidden --exclude .git'
(( $+commands[zoxide] )) && eval "$(zoxide init zsh)"
(( $+commands[starship] )) && eval "$(starship init zsh)"
[[ -r /etc/profile.d/debuginfod.sh ]] && source /etc/profile.d/debuginfod.sh
alias v=nvim
alias ll='eza -lah --icons --git --group-directories-first'
alias lt='eza --tree --level=2 --icons --group-directories-first'
alias lg=lazygit
alias gs='git status --short --branch'
alias gl='git log --graph --decorate --oneline --all'
alias catp='bat --paging=never'
alias ..='cd ..'
alias ...='cd ../..'
alias update='sudo pacman -Syu'
alias devhelp='less ~/DEV-SETUP.md'
alias devpy='source ~/.venvs/dev-tools/bin/activate'
[[ -r /usr/share/zsh/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh ]] && source /usr/share/zsh/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh
ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE='fg=8'
[[ -r /usr/share/zsh/plugins/zsh-history-substring-search/zsh-history-substring-search.zsh ]] && source /usr/share/zsh/plugins/zsh-history-substring-search/zsh-history-substring-search.zsh
bindkey '^[[A' history-substring-search-up
bindkey '^[[B' history-substring-search-down
bindkey '^[[H' beginning-of-line
bindkey '^[[F' end-of-line
[[ -r /usr/share/zsh/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh ]] && source /usr/share/zsh/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh

export SSH_AUTH_SOCK="${XDG_RUNTIME_DIR:-/run/user/$(id -u)}/ssh-agent.socket"
