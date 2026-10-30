# Interactive development shell for 1337 / Ubuntu.
[[ -o interactive ]] || return

export EDITOR=nvim
export VISUAL=nvim
export LESS='-R'

# Ensure PATH includes all user-installed binaries
typeset -U path fpath
path=($HOME/.local/bin $HOME/bin $HOME/.npm-global/bin $path)
fpath=($HOME/.local/share/zsh/site-functions $fpath)
export PATH

HISTFILE=$HOME/.zsh_history
HISTSIZE=50000
SAVEHIST=50000
setopt APPEND_HISTORY SHARE_HISTORY HIST_IGNORE_ALL_DUPS HIST_IGNORE_SPACE HIST_REDUCE_BLANKS
setopt AUTO_CD INTERACTIVE_COMMENTS NO_BEEP
bindkey -e
zmodload zsh/complist
autoload -Uz compinit
compinit -u

zstyle ':completion:*' menu select
zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}'
zstyle ':completion:*' list-colors ${(s.:.)LS_COLORS}

# FZF key bindings & completion (local first, then system)
if [[ -r "$HOME/.local/share/fzf/key-bindings.zsh" ]]; then
  source "$HOME/.local/share/fzf/key-bindings.zsh"
elif [[ -r /usr/share/fzf/key-bindings.zsh ]]; then
  source /usr/share/fzf/key-bindings.zsh
fi

if [[ -r "$HOME/.local/share/fzf/completion.zsh" ]]; then
  source "$HOME/.local/share/fzf/completion.zsh"
elif [[ -r /usr/share/fzf/completion.zsh ]]; then
  source /usr/share/fzf/completion.zsh
fi

export FZF_DEFAULT_COMMAND='fd --type f --hidden --exclude .git'
export FZF_DEFAULT_OPTS='--height=45% --layout=reverse --border=rounded --color=bg:#000000,bg+:#202020,fg:#cccccc,fg+:#ffffff,hl:#91b4d5,hl+:#91b4d5,border:#444444,pointer:#a3c99c'
export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
export FZF_ALT_C_COMMAND='fd --type d --hidden --exclude .git'

# Tools initialization
(( $+commands[zoxide] )) && eval "$(zoxide init zsh)"
(( $+commands[starship] )) && eval "$(starship init zsh)"

# Aliases - Modern CLI replacements
alias v="$HOME/.local/bin/nvim"
alias vi="$HOME/.local/bin/nvim"
(( $+commands[eza] )) && alias ll='eza -lah --icons --git --group-directories-first' || alias ll='ls -lah --color=auto'
(( $+commands[eza] )) && alias lt='eza --tree --level=2 --icons --group-directories-first'
(( $+commands[lazygit] )) && alias lg=lazygit
(( $+commands[bat] )) && alias catp='bat --paging=never'
alias gs='git status --short --branch'
alias gl='git log --graph --decorate --oneline --all'
alias ..='cd ..'
alias ...='cd ../..'

# 1337-specific shortcuts & storage tracking
alias quota="df -h ~"
alias movespace="du -sh * 2>/dev/null | sort -hr | head -n 10"
alias gst="git status"
alias gaa="git add ."
alias gcm="git commit -m"
alias gp="git push"
alias gcl="git clone"
alias catssh="cat ~/.ssh/id_ed25519.pub 2>/dev/null"
alias testssh="ssh -T git@github.com"
alias code='/goinfre/tlaghzal/VSCode-linux-x64/bin/code'
alias zen='~/.local/bin/zen'
alias uvi='uv pip install'
alias uvr='uv run'
alias uvv='uv venv'
alias uvp='uv python'
alias tyc='ty check'

# Large model & package caches redirected to goinfre to preserve quota
export GOINFRE_USER="/goinfre/tlaghzal"
export HF_HOME="$GOINFRE_USER/.cache/huggingface"
export HF_HUB_CACHE="$GOINFRE_USER/.cache/huggingface/hub"
export HF_DATASETS_CACHE="$GOINFRE_USER/.cache/huggingface/datasets"
export TORCH_HOME="$GOINFRE_USER/.cache/torch"
export UV_CACHE_DIR="$GOINFRE_USER/.uv_cache"
export PIP_CACHE_DIR="$GOINFRE_USER/.cache/pip"
unset TRANSFORMERS_CACHE

# ZSH plugins (local first, then system)
if [[ -r "$HOME/.local/share/zsh/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh" ]]; then
  source "$HOME/.local/share/zsh/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh"
elif [[ -r /usr/share/zsh/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh ]]; then
  source /usr/share/zsh/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh
fi
ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE='fg=8'

if [[ -r "$HOME/.local/share/zsh/plugins/zsh-history-substring-search/zsh-history-substring-search.zsh" ]]; then
  source "$HOME/.local/share/zsh/plugins/zsh-history-substring-search/zsh-history-substring-search.zsh"
elif [[ -r /usr/share/zsh/plugins/zsh-history-substring-search/zsh-history-substring-search.zsh ]]; then
  source /usr/share/zsh/plugins/zsh-history-substring-search/zsh-history-substring-search.zsh
fi
bindkey '^[[A' history-substring-search-up
bindkey '^[[B' history-substring-search-down
bindkey '^[[H' beginning-of-line
bindkey '^[[F' end-of-line

if [[ -r "$HOME/.local/share/zsh/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh" ]]; then
  source "$HOME/.local/share/zsh/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh"
elif [[ -r /usr/share/zsh/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh ]]; then
  source /usr/share/zsh/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
fi

# Neofetch on terminal startup (Carbon-styled)
if [[ -o interactive ]] && (( ! ${+NVIM} )) && command -v neofetch >/dev/null; then
  neofetch
fi


export PATH="$HOME/.local/bin:$PATH" # 1337-session

alias cclean='bash ~/LinuxCleaner_42.sh'

# Spotify background launcher
alias music='nohup ~/.local/bin/spotify-fixed >/dev/null 2>&1 </dev/null & disown'


alias vim="$HOME/.local/bin/nvim"
alias nv="$HOME/.local/bin/nvim"
