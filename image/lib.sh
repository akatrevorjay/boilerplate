#!/bin/bash
#
# Library functions for shell scripts.
#
set -eo pipefail

SELF="${0##*/}"

_script_echo()   {
	local level="$1" fmt="$2" date=$(date)
	printf "[%s] %s[%d] $fmt #%s\n" "$date" "$SELF" "$$" "${@:3}" "$level" >&2;
}

debug()          { [[ -z "$DEBUG" ]] || _script_echo DEBUG "$@"; }
e()              { [[ -n "$QUIET" ]] || _script_echo INFO "$@"; }
info()           { e "$@"; }
warn()           { [[ -n "$QUIET" ]] || _script_echo WARNING "$@"; }
warning()        { warn "$@"; }
error()          { _script_echo ERROR "$@" >&2; }
death()          { error "$@"; exit ${retval:-1}; }

# output control
nullify()        { "$@" >/dev/null 2>&1; }
errnullify()     { "$@" 2>/dev/null; }

debug_call()     { debug 'call: %s' "$*"; "$@"; }

##
## Defer commands until runtime
##

: ${RUNTIME_DEFERRED:="$IMAGE_ROOT/runtime.d"}

##
## Utils (must be in-process, hence placement here).
##

abspath() {
	(cd "$1" && pwd)
}

first-in() {
	local predicate="$1"
	shift 1

	local item
	for item in "$@"; do
		$predicate "$item" || continue

		echo "$item"
		return
	done

	return 1
}

abself() {
	local dir base
	dir=$(abspath "${PWD%/}/${0%/*}")
	base="${0##*/}"
	echo "$dir/$base"
}

save-retval() {
	local -n rv_ref=$1; shift
	"$@" && rv_ref=0 || rv_ref=$?
	return $rv_ref
}

assert() {
	local rv
	if ! save-retval rv "$@"; then
		error "Assertion failed (retval=%d) for command: %s" "$rv" "$*"
	fi
	return $rv
}

##
## uid/pid related
##

get_uid_of_pid() { ps -o uid= "$1" | sed -e 's/^ //g'; }
get_uid_of_user() { id -u "$1"; }

ppid_is_init() { [[ $PPID -eq 1 ]]; }
pid_is_init() { [[ ${1:-$$} -eq 1 ]]; }

is_number() {
	# This code block looks like a space ship.
	case "$*" in
		''|*[!0-9]*) return 1 ;;
		*) : ;;
	esac
}

ensure_alphanum() {
	echo "${@//[^[:alpha:][:digit:]]/_}"
}

