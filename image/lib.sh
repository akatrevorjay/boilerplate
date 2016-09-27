#!/bin/bash
set -eo pipefail

SELF="$(basename "$0")"

function _script_echo   { echo "[$(date)] $0[$$]" "${@:2}" "#$1"; }
function debug          { [[ -z "$ENTRYPOINT_DEBUG" ]] || _script_echo DEBUG "$@"; }
function e              { [[ -n "$ENTRYPOINT_QUIET" ]] || _script_echo INFO "$@"; }
function info           { e "$@"; }
function warn           { [[ -n "$ENTRYPOINT_QUIET" ]] || _script_echo WARNING "$@"; }
function warning        { warn "$@"; }
function error          { _script_echo ERROR "$@" >&2; }
function death          { error "$@"; exit 1; }
function debug_call     { debug 'call:' "$@"; "$@"; }

##
## Defer commands until runtime
##

ENTRYPOINT_RUN="/run/entrypoint"
RUNTIME_DEFERRED="$IMAGE_ROOT/libexec/at_runtime"

function at_runtime {
    echo "$@" >> "$RUNTIME_DEFERRED"
}

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

##
## Entrypoint related
##

function entrypoint_hook {
    local hook="$1"; shift
    debug "Hook: $hook"
    local path= hook_path=
    for path in ${ENTRYPOINT_PATH//:/ }; do
        hook_path="$path/hook_$hook"

        if [[ -e "$hook_path" ]]; then
            e "Hook: $hook: $hook_path"
            trap '$? && continue' EXIT
            . "$hook_path"
            trap - EXIT
        fi
    done
}

function entrypoint_find {
    # Find if any entrypoints exist with this name
    # This way we don't add ENTRYPOINT_PATH to PATH
    local which="$(which which)"  # Nab the abs path
    PATH="$ENTRYPOINT_PATH" "$which" "$1"
}

function entrypoint_exec {
    debug "run_entrypoint:" "$@"

    entrypoint="$(entrypoint_find "$1" || :)"
    if [[ -n "$entrypoint" ]]; then
        e "entrypoint: $entrypoint (resolved from $1)"

        # Replace first element with the full path to the entrypoint, keep the rest
        set -- "$entrypoint" "${@:2}"
    fi

    local prefix
    if pid_is_init && test -n "$*"; then
        # Use dumb-init by default on exec from init, but allow
        # it to be replaced.
        prefix="dumb-init --single-child"
    fi
    prefix="$(namespace get EXEC_PREFIX "$prefix")"
    debug "prefix: $prefix"

    e "exec:" "$@"
    entrypoint_hook "exec_$1" "exec"
    debug_call exec $prefix "$@"
}

##
## Flags; auto set when this is sourced with $SELF
## meant to be able to tell what context you're in
##

function flag {
    local -u name="__${1:-$SELF}"
    local value="${2:-true}"
    read -r "$name" <<< "$value"
}

function get_flag {
    local -u name="__$1"
    local default="$2"
    echo "${!entrypoint_var:-$default}"
}

function has_flag {
    local value=$(get_flag "$@")
    return [[ -n "$value" ]]
}

##
## Env namespacing
##

# This is horrible but I don't trust people to explicity set it when
# creating new entrypoints.
function namespace {
    local cmd="$1"; shift
    case "$cmd" in
        get|getset)
            local name="$1" default="$2" opts="$3"
            local var="${ENTRYPOINT_NAMESPACE}_$name" value=

            for opt in "$opts"; do
                case "$opts" in
                    global)
                        default="${!name:-$default}"
                        ;;&
                    *)
                        local entrypoint_var="ENTRYPOINT_$name"
                        default="${!entrypoint_var:-$default}"
                        ;;
                esac
            done

            value="${!var:-$default}"
            echo "$value"
            ;;&
        getset)
            set -- "$var" "$value"
            ;;&
        set)
            local name="$1" value="$2"
            read -r "$name" <<< "$value"
            ;;&
    esac
}

##
## Init
##

function _image_lib_init {
    [[ -n "$ENTRYPOINT_NAMESPACE" ]] \
        || declare -u ENTRYPOINT_NAMESPACE="$(basename "$0" | tr -cd '[[:alnum:]]_')"

    : ${ENTRYPOINT_QUIET:=$(namespace get QUIET)}

    : ${ENTRYPOINT_TRACE:=$(namespace get TRACE)}
    if [[ -n "$ENTRYPOINT_TRACE" ]]; then
        set -x
        ENTRYPOINT_DEBUG=1
    fi

    : ${ENTRYPOINT_DEBUG:=$(namespace get DEBUG)}
    if [[ -n "$ENTRYPOINT_DEBUG" ]]; then
        set -v
        unset ENTRYPOINT_QUIET
    fi

    debug "Namespace: $ENTRYPOINT_NAMESPACE"
    flag "$SELF"
    entrypoint_hook "init"
}

# run init
_image_lib_init

