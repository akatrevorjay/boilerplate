#!/usr/bin/env bats
set -eo pipefail
shopt -s nullglob

: ${IMAGE:?}

save-retval() {
	local -n rv_ref=$1; shift
	"$@" && rv_ref=0 || rv_ref=$?
	return $rv_ref
}

run-in-image() {
	local dargs=()

	local arg
	for arg in "$@"; do
		shift
		[[ "$arg" != "--" ]] || break
		dargs+=("$arg")
	done

	local cmd=(
		docker run
		--rm
		"${dargs[@]}"
		"${IMAGE:?}"
		"$@"
	)

	save-retval rv "${cmd[@]}"
}

@test "[entrypoint] shell hello world" {
	expected="hello world"
	result=$(run-in-image -- bash -c "echo -n $expected")
	[[ "$result" == "$expected" ]]
}

@test "[build-parts] bad shebang results in expected failure" {
	! run-in-image -- bash -c $'
		( \
			mkdir -pv test-parts && cd test-parts \
			\
			&& echo \'#!/fake/shebang\' > failure-part \
			&& chmod +x failure-part \
			\
		 ) && \
		 \
		 build-parts test-parts'
}

@test "[build-parts] validate successful multi-step execution." {
	local out
	out=$(run-in-image -- bash -c $'
		( \
			mkdir -pv test-parts && cd test-parts \
			\
			&& for p in part{1..5}; do \
				echo -e \'#!/bin/sh\necho "self=$(basename "$0")"\' > "$p" \
				&& chmod +x "$p" \
				; \
			done; \
			\
		 ) && \
		 \
		 build-parts test-parts' \
		 )

	for p in part{1..5}; do
		echo "$out" | grep -- "self=$p"
	done
}

