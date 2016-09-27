MAKEFLAGS += --warn-undefined-variables

IMAGE = $(PARENT_IMAGE)-test
BUILD = docker build
RUN ?= docker run -it --rm -v $(CURDIR)/../../image:/image

.PHONY: all build Dockerfile.pp

all: test

clean:
	rm -f Dockerfile.pp

Dockerfile.pp: Dockerfile
	sed -e 's@^\(FROM\).*$$@\1 $(PARENT_IMAGE)@' $^ > $@.new
	@mv -v $@.new $@

build: Dockerfile.pp
	$(BUILD) -f $^ -t $(IMAGE) .

test: build
	$(RUN)

bash:
	$(RUN) $(IMAGE) bash

bash-verbose:
	$(RUN) -e ENTRYPOINT_VERBOSE=1 $(IMAGE) bash

bash-debug:
	$(RUN) -e ENTRYPOINT_DEBUG=1 $(IMAGE) bash

bash-trace:
	$(RUN) -e ENTRYPOINT_TRACE=1 $(IMAGE) bash
