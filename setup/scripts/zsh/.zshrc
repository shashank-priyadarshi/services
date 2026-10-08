export PATH="$HOME/.local/bin:$HOME/bin:$PATH"
export PATH="$HOME/.kimi-code/bin:$HOME/.codeium/windsurf/bin:$HOME/.grok/bin:$HOME/.sopmod/bin:$PATH"
export PATH="$HOME/.antigravity/antigravity/bin:$HOME/.antigravity-ide/antigravity-ide/bin:$PATH"
export PATH="/opt/podman/bin:/opt/homebrew/opt/postgresql@17/bin:$PATH"

typeset -U path PATH
path=(/opt/homebrew/bin /opt/homebrew/sbin /usr/bin /bin /usr/sbin /sbin $path)

if [[ -z "$TMUX" ]] && (( $+commands[tmux] )); then
  tmux new-session
fi

GPG_TTY=$(tty)
export GPG_TTY

prompt_git_path() {
  local prefix

  if prefix=$(git rev-parse --show-prefix 2>/dev/null); then
    prefix=${prefix%/}
    printf '%s::' "$prefix"
  else
    printf '::'
  fi
}

setopt PROMPT_SUBST
PS1='$(prompt_git_path) '

source ~/.zsh_aliases

export LDFLAGS="-L/opt/homebrew/opt/postgresql@17/lib"
export CPPFLAGS="-I/opt/homebrew/opt/postgresql@17/include"

export JAVA_HOME=$(/usr/libexec/java_home)
export PATH="$(brew --prefix openjdk@27)/bin:$PATH"

# Real docker command for Maven/Spring (symlink, not alias)
unalias docker 2>/dev/null
if [[ ! -x "$HOME/bin/docker" && -x "$(command -v podman)" ]]; then
  mkdir -p "$HOME/bin"
  ln -sf "$(command -v podman)" "$HOME/bin/docker"
fi

# Host socket for Docker-compatible clients (skip if machine is down)
if command -v podman >/dev/null 2>&1; then
  _podman_sock="$(podman machine inspect --format '{{.ConnectionInfo.PodmanSocket.Path}}' 2>/dev/null)"
  if [[ -n "$_podman_sock" && -S "$_podman_sock" ]]; then
    export DOCKER_HOST="unix://$_podman_sock"
  fi
  unset _podman_sock
fi

[[ ! -r "$HOME/.opam/opam-init/init.zsh" ]] ||
  source "$HOME/.opam/opam-init/init.zsh" >/dev/null 2>&1

if [[ -f "$HOME/Downloads/google-cloud-cli-darwin-x86_64/google-cloud-sdk/path.zsh.inc" ]]; then
  source "$HOME/Downloads/google-cloud-cli-darwin-x86_64/google-cloud-sdk/path.zsh.inc"
fi

if [[ -f "$HOME/Downloads/google-cloud-cli-darwin-x86_64/google-cloud-sdk/completion.zsh.inc" ]]; then
  source "$HOME/Downloads/google-cloud-cli-darwin-x86_64/google-cloud-sdk/completion.zsh.inc"
fi

fpath=("$HOME/.zsh/completions" $fpath)
if (( $+commands[fzf] )); then
  # Open fzf on a plain Tab instead of requiring the ** trigger.
  export FZF_COMPLETION_TRIGGER=''

  # Directories that are listed but never descended into, unless the
  # completion already starts inside one of them. Glob patterns allowed.
  _fzf_skip_names=(
    '.*' node_modules vendor target dist build
    venv __pycache__ bower_components
  )

  # Specific directories skipped unless the completion starts inside them.
  _fzf_skip_paths=(
    ~/go ~/go/pkg ~/Library ~/Downloads
    ~/Applications ~/Movies ~/Music ~/Pictures
  )

  # How many levels below the starting directory to search: Tab lists
  # the current directory only, Shift-Tab searches recursively.
  _fzf_max_depth=4
  _fzf_depth=1

  # Recursively list paths under $1 without walking skipped directories.
  # $2 is "d" to list only directories.
  _fzf_walk() {
    local base=${1%/} abs=${1:A} name
    local -a prune type

    [[ -z $base ]] && base=/
    [[ $2 == d ]] && type=(-type d)

    for name in $_fzf_skip_names; do
      [[ /$abs/ == */${~name}/* ]] && continue
      prune+=(-name "$name" -o)
    done

    for name in $_fzf_skip_paths; do
      [[ $name == ${abs%/}/* ]] || continue
      prune+=(-path "$base/${name#${abs%/}/}" -o)
    done

    command find -L "$base" -mindepth 1 -maxdepth $_fzf_depth \
      \( \( "${prune[@]}" -false \) -prune $type -print \) -o \
      \( $type -print \) 2>/dev/null |
      command sed 's@^\./@@'
  }

  _fzf_compgen_path() { _fzf_walk "$1" }
  _fzf_compgen_dir() { _fzf_walk "$1" d }

  source <(fzf --zsh)

  fzf-shallow-completion() {
    _fzf_depth=1
    zle fzf-completion
  }

  fzf-deep-completion() {
    _fzf_depth=$_fzf_max_depth
    zle fzf-completion
    _fzf_depth=1
  }

  zle -N fzf-shallow-completion
  zle -N fzf-deep-completion
  bindkey '^I' fzf-shallow-completion
  bindkey '^[[Z' fzf-deep-completion
fi

[[ "$TERM_PROGRAM" == "kiro" ]] && . "$(kiro --locate-shell-integration-path zsh)"
[ -f "$HOME/.ghcup/env" ] && . "$HOME/.ghcup/env" # ghcup-env

# OPENSPEC:START
# OpenSpec shell completions configuration
fpath=("$HOME/.zsh/completions" $fpath)
autoload -Uz compinit
compinit
# OPENSPEC:END

# >>> grok installer >>>
fpath=(~/.grok/completions/zsh $fpath)
autoload -Uz compinit && compinit -C
# <<< grok installer <<<
