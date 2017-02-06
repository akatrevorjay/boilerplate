#!/usr/bin/env bats

: ${IMAGE:?}

run-in-image() {
	docker run -it "${IMAGE:?}" "$@"
}

@test "Simple shell hello world" {
	expected="hello world"
	result=$(run-in-image bash -c "echo -n $expected")
	[[ "${result}" == "${expected}" ]]
}
