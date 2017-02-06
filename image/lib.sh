#!/bin/bash
#
# Library functions for shell scripts.
#
set -eo pipefail

SELF="${0##*/}"

function _script_echo   { printf "[$(date)] $SELF[$$] $2 #$1\n" "${@:3}" >&2; }
function debug          { [[ -z "$DEBUG" ]] || _script_echo DEBUG "$@"; }
function e              { [[ -n "$QUIET" ]] || _script_echo INFO "$@"; }
function info           { e "$@"; }
function warn           { [[ -n "$QUIET" ]] || _script_echo WARNING "$@"; }
function warning        { warn "$@"; }
function error          { _script_echo ERROR "$@" >&2; }
function death          { error "$@"; exit 1; }
function debug_call     { debug 'call: %s' "$*"; "$@"; }
function nullify        { "$@" >/dev/null 2>&1; }
function errnullify     { "$@" 2>/dev/null; }

##
## Defer commands until runtime
##

: ${RUNTIME_DEFERRED:="$IMAGE_ROOT/runtime.d"}

##
## Utils
##

get_uid_of_pid() { ps -o uid= "$1" | sed -e 's/^ //g'; }
get_uid_of_user() { id -u "$1"; }

function ppid_is_init { [[ $PPID -eq 1 ]]; }
function pid_is_init { [[ ${1:-$$} -eq 1 ]]; }

function is_number {
	# This code block looks like a space ship.
	case "$*" in
		''|*[!0-9]*) return 1 ;;
		*) : ;;
	esac
}

function ensure_alphanum {
	echo "${@//[^[:alpha:][:digit:]]/_}"
}
