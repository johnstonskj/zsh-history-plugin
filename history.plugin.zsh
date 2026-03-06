# -*- mode: sh; eval: (sh-set-shell "zsh") -*-
#
# Plugin Name: history
# Description: Zsh plugin to configure core history functionality.
# Repository: https://github.com/johnstonskj/zsh-history-plugin
#
# Public variables:
#

############################################################################
# @section Lifecycle
# @description Plugin lifecycle functions.
#

history_plugin_init() {
    builtin emulate -L zsh

    @zplugins_envvar_save history HISTFILE
    export HISTFILE="${ZSH_STATE_HOME}/history"

    @zplugins_envvar_save history HISTSIZE
    export HISTSIZE=10000           # Maximum lines kept in memory

    @zplugins_envvar_save history SAVEHIST
    export SAVEHIST=100000          # Maximum lines saved to ${HISTFILE}

    setopt EXTENDED_HISTORY         # Write the history file in the ':start:elapsed;command' format.
    setopt SHARE_HISTORY            # Share history between all sessions.
    setopt HIST_EXPIRE_DUPS_FIRST   # Expire a duplicate event first when trimming history.
    setopt HIST_IGNORE_DUPS         # Do not record an event that was just recorded again.
    setopt HIST_IGNORE_ALL_DUPS     # Delete an old recorded event if a new event is a duplicate.
    setopt HIST_FIND_NO_DUPS        # Do not display a previously found event.
    setopt HIST_IGNORE_SPACE        # Do not record an event starting with a space.
    setopt HIST_SAVE_NO_DUPS        # Do not write a duplicate event to the history file.
    setopt HIST_VERIFY              # Do not execute immediately upon history expansion.
    setopt APPEND_HISTORY           # append to history file
    setopt HIST_NO_STORE            # Don't store history commands
}

history_plugin_unload() {
    builtin emulate -L zsh

    @zplugins_envvar_restore history HISTFILE
    @zplugins_envvar_restore history HISTSIZE
    @zplugins_envvar_restore history SAVEHIST
}


############################################################################
# @section Public
# @description History utility functions.
#

function he() {
    # check if we passed any parameters
    if [ -z "$*" ]; then
        # if no parameters were passed print entire history
        history 1
    else
        # if words were passed use it as a search
        history 1 | egrep --color=auto "$@"
    fi
}
@zplugins_remember_fn history he

function hf() {
    eval $( ([ -n "${ZSH_NAME}" ] && fc -l 1 || history) | fzf +s --tac | sed 's/ *[0-9]* *//')
}
@zplugins_remember_fn history hf
