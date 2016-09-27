MAKEFLAGS += --warn-undefined-variables

# Do not:
# o  use make's built-in rules and variables
#    (this increases performance and avoids hard-to-debug behaviour);
# o  print "Entering directory ...";
MAKEFLAGS += -rR --no-print-directory

REPO = trevorj/docker-boilerplate
BUILD_TAG = build
IMAGE = $(REPO):$(BUILD_TAG)

export REPO IMAGE BUILD_TAG

BUILD = docker build
RUN ?= docker run -it --rm -v $(PWD)/image:/image
BIN ?= image/bin

GOLANG_IMAGE = golang:1.7
GOLANG_BUILD = docker run --rm -it -v $(PWD)/$(BIN):/go/bin $(GOLANG_IMAGE)
GOLANG_DEPS = $(BIN)/boilr
REPO_$(BIN)/boilr = github.com/tmrts/boilr

BUILD_DEPS = $(GOLANG_DEPS)
DEPS = $(BUILD_DEPS)

.PHONY: all deps build test
all: build

$(GOLANG_DEPS):
	$(GOLANG_BUILD)	go get -u -x -v $(REPO_$@)

clean:
	rm -rf $(BUILD_DEPS)

deps: $(DEPS)

build: deps
	$(BUILD) -t $(IMAGE) .

test: build
	$(MAKE) -C tests PARENT_IMAGE=$(IMAGE)

bash: build
	$(RUN) $(IMAGE) bash

bash-verbose: build
	$(RUN) -e ENTRYPOINT_VERBOSE=1 $(IMAGE) bash

bash-debug: build
	$(RUN) -e ENTRYPOINT_DEBUG=1 $(IMAGE) bash

bash-trace: build
	$(RUN) -e ENTRYPOINT_TRACE=1 $(IMAGE) bash
