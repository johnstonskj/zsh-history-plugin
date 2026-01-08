# -*- mode: sh; eval: (sh-set-shell "zsh") -*-
#
# Plugin Name: history
# Repository: https://github.com/johnstonskj/zsh-history-plugin
#
# Description:
#
#   Zsh plugin to configure core history functionality.
#
# Public variables:
#
# * `HISTORY`; plugin-defined global associative array with the following keys:
#   * `_ALIASES`; a list of all aliases defined by the plugin.
#   * `_FUNCTIONS`; a list of all functions defined by the plugin.
#   * `_PLUGIN_DIR`; the directory the plugin is sourced from.
# * `HISTORY_EXAMPLE`; if set it does something magical.
#

############################################################################
# Standard Setup Behavior
############################################################################

# See https://wiki.zshell.dev/community/zsh_plugin_standard#zero-handling
0="${ZERO:-${${0:#$ZSH_ARGZERO}:-${(%):-%N}}}"
0="${${(M)0:#/*}:-$PWD/$0}"

# See https://wiki.zshell.dev/community/zsh_plugin_standard#standard-plugins-hash
declare -gA HISTORY
HISTORY[_PLUGIN_DIR]="${0:h}"
HISTORY[_ALIASES]=""
HISTORY[_FUNCTIONS]=""

############################################################################
# Internal Support Functions
############################################################################

#
# This function will add to the `HISTORY[_FUNCTIONS]` list which is
# used at unload time to `unfunction` plugin-defined functions.
#
# See https://wiki.zshell.dev/community/zsh_plugin_standard#unload-function
# See https://wiki.zshell.dev/community/zsh_plugin_standard#the-proposed-function-name-prefixes
#
.history_remember_fn() {
    builtin emulate -L zsh

    local fn_name="${1}"
    if [[ -z "${HISTORY[_FUNCTIONS]}" ]]; then
        HISTORY[_FUNCTIONS]="${fn_name}"
    elif [[ ",${HISTORY[_FUNCTIONS]}," != *",${fn_name},"* ]]; then
        HISTORY[_FUNCTIONS]="${HISTORY[_FUNCTIONS]},${fn_name}"
    fi
}
.history_remember_fn .history_remember_fn

.history_define_alias() {
    local alias_name="${1}"
    local alias_value="${2}"

    alias ${alias_name}=${alias_value}

    if [[ -z "${HISTORY[_ALIASES]}" ]]; then
        HISTORY[_ALIASES]="${alias_name}"
    elif [[ ",${HISTORY[_ALIASES]}," != *",${alias_name},"* ]]; then
        HISTORY[_ALIASES]="${HISTORY[_ALIASES]},${alias_name}"
    fi
}
.history_remember_fn .history_remember_alias

#
# This function does the initialization of variables in the global variable
# `HISTORY`. It also adds to `path` and `fpath` as necessary.
#
history_plugin_init() {
    builtin emulate -L zsh
    builtin setopt extended_glob warn_create_global typeset_silent no_short_loops rc_quotes no_auto_pushd

    export HISTFILE="${ZSH_STATE_HOME}/history"

    export HISTSIZE=10000           # Maximum lines kept in memory
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
.history_remember_fn history_plugin_init

############################################################################
# Plugin Unload Function
############################################################################

# See https://wiki.zshell.dev/community/zsh_plugin_standard#unload-function
history_plugin_unload() {
    builtin emulate -L zsh

    # Remove all remembered functions.
    local plugin_fns
    IFS=',' read -r -A plugin_fns <<< "${HISTORY[_FUNCTIONS]}"
    local fn
    for fn in ${plugin_fns[@]}; do
        whence -w "${fn}" &> /dev/null && unfunction "${fn}"
    done
    
    # Remove all remembered aliases.
    local aliases
    IFS=',' read -r -A aliases <<< "${HISTORY[_ALIASES]}"
    local alias
    for alias in ${aliases[@]}; do
        unalias "${alias}"
    done

    # Remove the global data variable (after above!).
    unset HISTORY

    # Remove this function last.
    unfunction history_plugin_unload
}

############################################################################
# Public Functions
############################################################################

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
.history_remember_fn he

function hf() {
    eval $( ([ -n "${ZSH_NAME}" ] && fc -l 1 || history) | fzf +s --tac | sed 's/ *[0-9]* *//')
}
.history_remember_fn hf

############################################################################
# Initialize Plugin
############################################################################

history_plugin_init

true
