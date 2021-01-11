# vim:ft=zsh ts=2 sw=2 sts=2
#
# Based on agnoster's Theme - https://gist.github.com/3712874
# A Powerline-inspired theme for ZSH
#
# # README
#
# In order for this theme to render correctly, you will need a
# [Powerline-patched font](https://gist.github.com/1595572).
#
# In addition, I recommend the
# [Solarized theme](https://github.com/altercation/solarized/) and, if you're
# using it on Mac OS X, [iTerm 2](http://www.iterm2.com/) over Terminal.app -
# it has significantly better color fidelity.
#
# # Goals
#
# The aim of this theme is to only show you *relevant* information. Like most
# prompts, it will only show git information when in a git working directory.
# However, it goes a step further: everything from the current user and
# hostname to whether the last call exited with an error to whether background
# jobs are running in this shell will all be displayed automatically when
# appropriate.

### Segment drawing
# A few utility functions to make it easy and re-usable to draw segmented prompts

_PROMPT_DIR=${0:A:h}

CURRENT_BG='NONE'
SEGMENT_SEPARATOR=$'\ue0b0'

ONLINE='%{%F{green}%}\u29bf'
OFFLINE='%{%F{red}%}\u29be'

# Default values for the appearance of the prompt. Configure at will.
#«»±˖˗‑‐‒━✚‐↔←↑↓→↭⇎⇔⋆━◂▸◄►◆☀★☗☊✔✖❮❯⚑⚙✎●…
ZSH_THEME_GIT_PROMPT_REF=$'\ue0a0 '
ZSH_THEME_GIT_PROMPT_CHANGED=$'\u270e '
ZSH_THEME_GIT_PROMPT_CONFLICTS=$'\u2716 '
ZSH_THEME_GIT_PROMPT_STAGED=$'\u271a '
ZSH_THEME_GIT_PROMPT_BEHIND=$'\u2193'
ZSH_THEME_GIT_PROMPT_AHEAD=$'\u2191'
ZSH_THEME_GIT_PROMPT_UNTRACKED=$'\u2026'
ZSH_THEME_GIT_PROMPT_CLEAN=$'\u2714'
ZSH_THEME_GIT_DETACHED_HEAD=$'\u27a6 '


# Begin a segment
# Takes two arguments, background and foreground. Both can be omitted,
# rendering default background/foreground.
prompt_segment() {
  local bg fg
  [[ -n $1 ]] && bg="%K{$1}" || bg="%k"
  [[ -n $2 ]] && fg="%F{$2}" || fg="%f"
  if [[ $CURRENT_BG != 'NONE' && $1 != $CURRENT_BG ]]; then
    echo -n " %{$bg%F{$CURRENT_BG}%}$SEGMENT_SEPARATOR%{$fg%} "
  else
    echo -n "%{$bg%}%{$fg%} "
  fi
  CURRENT_BG=$1
  [[ -n $3 ]] && echo -n $3
}

# End the prompt, closing any open segments
prompt_end() {
  if [[ -n $CURRENT_BG ]]; then
    echo -n " %{%k%F{$CURRENT_BG}%}$SEGMENT_SEPARATOR"
  else
    echo -n "%{%k%}"
  fi
  echo -n "%{%f%}"
  CURRENT_BG=''
}

### Prompt components
# Each component will draw itself, and hide itself if no information needs to be shown

# Context: user@hostname (who am I and where am I)
prompt_context() {
  if [[ -n $SSH_CONNECTION ]]; then
    local user=`whoami`

    if [[ "$user" != "$DEFAULT_USER" || -n "$SSH_CLIENT" ]]; then
      prompt_segment black white "$user@%m"
    fi
  fi
}

# Git: branch/detached head, dirty status
prompt_git() {
  if $(git rev-parse --is-inside-work-tree >/dev/null 2>&1); then
    GIT_CHANGED_FILES=( $(git diff --name-status | awk -v ORS=", " '//{print $1}' | head -c -2) )
    GIT_STAGED_FILES=( $(git diff --name-status --staged | awk -v ORS=", " '//{print $1}' | head -c -2) )
    GIT_N_CONFLITS=$(grep -o 'U' <<< ${GIT_STAGED_FILES[*]} | wc -l) 
    GIT_N_STAGED=$(( ${#GIT_STAGED_FILES[@]} - $GIT_N_CONFLITS ))
    GIT_N_UNTRACKED=$(git status --porcelain | grep '??' | wc -l)
    GIT_N_CHANGED=$(( ${#GIT_CHANGED_FILES[@]} - `grep -o 'U' <<< ${GIT_CHANGED_FILES[*]} | wc -l` ))

    __BRANCH=false
    __REMOTE=false
    GIT_N_AHEAD=0
    GIT_N_BEHIND=0
    GIT_STATUS=""
    GIT_FG=
    GIT_BG=

    GIT_REF=$(git symbolic-ref HEAD 2> /dev/null) && __BRANCH=true || GIT_REF="${ZSH_THEME_GIT_DETACHED_HEAD}:$(git show-ref --head -s --abbrev | head -n1 2> /dev/null)"
    GIT_BRANCH=$(echo -n "${GIT_REF}" | sed -e "s/refs\/heads\///g")
    GIT_PROMPT_REF=$(echo -n "${GIT_REF}" | sed -e "s/refs\/heads\//${ZSH_THEME_GIT_PROMPT_REF}/g")

    if ${__BRANCH}; then
        GIT_REMOTE=$(git config branch.`echo $GIT_BRANCH`.remote 2> /dev/null) && __REMOTE=true
        if ${__REMOTE}; then 
            GIT_MERGE_REF=$(git config branch.`echo $GIT_BRANCH`.merge)
            if [[ "${GIT_REMOTE}" == "." ]]; then
                GIT_REMOTE_REF="$(GIT_MERGE_REF)"
            else
                GIT_REMOTE_REF="refs/remotes/$GIT_REMOTE/${GIT_MERGE_REF:11}"
            fi
            GIT_UPSTREAM_DELTA=$(git rev-list --left-right ${GIT_REMOTE_REF}...HEAD)
            GIT_N_AHEAD=$(grep -o '^>' <<< $GIT_UPSTREAM_DELTA | wc -l)
            GIT_N_BEHIND=$(grep -o '^<' <<< $GIT_UPSTREAM_DELTA | wc -l)
        fi
    fi

    if [ "$GIT_N_CONFLICTS" -ne "0" ]; then
		  prompt_segment red white
	  else
      if [ "$GIT_N_CHANGED" -eq "0" ] && [ "$GIT_N_STAGED" -eq "0" ] && [ "$GIT_N_UNTRACKED" -eq "0" ]; then
		    if [ "$GIT_N_BEHIND" -ne "0" ]; then
		      prompt_segment magenta white
	      else
          if [ "$GIT_N_AHEAD" -ne "0" ]; then 
            prompt_segment cyan black
          else
            prompt_segment green black
          fi
        fi
	    else
        prompt_segment yellow black
      fi
    fi
	  
    if [ "$GIT_N_BEHIND" -ne "0" ] ||  [ "$GIT_N_AHEAD" -ne "0" ]; then
		  STATUS="$STATUS($ZSH_THEME_GIT_PROMPT_BEHIND$GIT_N_BEHIND$ZSH_THEME_GIT_PROMPT_AHEAD$GIT_N_AHEAD)"
	  fi
	  if [ "$GIT_N_STAGED" -ne "0" ]; then
		  STATUS="$STATUS $ZSH_THEME_GIT_PROMPT_STAGED$GIT_N_STAGED"
	  fi
	  if [ "$GIT_N_CONFLITS" -ne "0" ]; then
		  STATUS="$STATUS $ZSH_THEME_GIT_PROMPT_CONFLICTS$GIT_N_CONFLICTS"
	  fi
	  if [ "$GIT_N_CHANGED" -ne "0" ]; then
		  STATUS="$STATUS $ZSH_THEME_GIT_PROMPT_CHANGED$GIT_N_CHANGED"
	  fi
	  if [ "$GIT_N_UNTRACKED" -ne "0" ]; then
		  STATUS="$STATUS $ZSH_THEME_GIT_PROMPT_UNTRACKED"
	  fi
	  if [ "$GIT_N_CHANGED" -eq "0" ] && [ "$GIT_N_CONFLICTS" -eq "0" ] && [ "$GIT_N_STAGED" -eq "0" ] && [ "$GIT_N_UNTRACKED" -eq "0" ]; then
		  STATUS="$STATUS $ZSH_THEME_GIT_PROMPT_CLEAN"
	  fi

	  echo -n "${GIT_PROMPT_REF}${STATUS}"
  fi
}

function prompt_online() {
  if [[ "`${_PROMPT_DIR}/scripts/online-check`" -eq "0" ]]; then
    echo $OFFLINE
  else
    echo $ONLINE
  fi
}

# Dir: current working directory
prompt_dir() {
  prompt_segment blue black '%~'
}

# Status:
# - was there an error
# - am I root
# - are there background jobs?
prompt_status() {
  local symbols
  symbols=()
  [[ $RETVAL -ne 0 ]] && symbols+="%{%F{red}%}✘"
  [[ $UID -eq 0 ]] && symbols+="%{%F{yellow}%}⚡"
  [[ $(jobs -l | wc -l) -gt 0 ]] && symbols+="%{%F{cyan}%}⚙"

  [[ -n "$symbols" ]] && prompt_segment black default "$symbols"
}

function battery_charge {
  echo `${_PROMPT_DIR}/scripts/battery -ezb "/sys/class/power_supply/BAT1"`
}

## Main prompt
build_prompt() {
  RETVAL=$?
  prompt_context
  prompt_status
  prompt_git
  prompt_dir
  prompt_end
}

RPROMPT=''
#RPROMPT='$(prompt_online)  $(battery_charge)' 

PROMPT='%{%f%b%k%}$(build_prompt)
» '
