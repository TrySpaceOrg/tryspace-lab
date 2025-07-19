# Makefile for TrySpace Lab development
.PHONY: all build build-fsw build-gsw build-sim debug run clean container runtime

export BUILD_IMAGE_NAME ?= tryspace-lab

# Commands
all: build

build:
	$(MAKE) build-fsw

build-fsw:
	docker run --rm -it -v $(CURDIR):$(CURDIR) --name "tryspace_fsw_build" -w $(CURDIR)/fsw --sysctl fs.mqueue.msg_max=10000 --ulimit rtprio=99 --cap-add=sys_nice $(BUILD_IMAGE_NAME) make -j build-fsw

build-gsw:

build-sim:
	docker run --rm -it -v $(CURDIR):$(CURDIR) --name "tryspace_sim_build" -w $(CURDIR)/sim --sysctl fs.mqueue.msg_max=10000 --ulimit rtprio=99 --cap-add=sys_nice $(BUILD_IMAGE_NAME) make -j build-sim

debug:
	docker run --rm -it -v $(CURDIR):$(CURDIR) --name "tryspace_fsw_debug" -w $(CURDIR) --sysctl fs.mqueue.msg_max=10000 --ulimit rtprio=99 --cap-add=sys_nice $(BUILD_IMAGE_NAME) /bin/bash

clean:
	$(MAKE) clean-fsw
	$(MAKE) clean-gsw
	$(MAKE) clean-sim

clean-fsw:
	cd fsw && $(MAKE) clean

clean-gsw:
	

clean-sim:
	cd simulith && $(MAKE) clean

container:
	docker build -t $(BUILD_IMAGE_NAME) -f cfg/Dockerfile.base .

runtime:
	$(MAKE) container
	cd fsw && $(MAKE) runtime

start:
	$(MAKE) start-fsw
	$(MAKE) start-gsw
	$(MAKE) start-sim

start-fsw:
	cd fsw && $(MAKE) start

start-gsw:


start-sim:

stop:
	docker ps --filter name=tryspace-* --filter status=running -aq | xargs docker stop
