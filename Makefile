# Makefile for TrySpace Lab development
.PHONY: all build build-fsw build-gsw build-sim debug clean container runtime start stop

export BUILD_IMAGE_NAME ?= tryspace-lab

# Commands
all: runtime

env:
	@if [ ! -f $(CURDIR)/cfg/.env ]; then \
		echo "Creating $(CURDIR)/cfg/.env with current user UID/GID..."; \
		mkdir -p $(CURDIR)/cfg; \
		echo "UID=$$(id -u)" > $(CURDIR)/cfg/.env; \
		echo "GID=$$(id -g)" >> $(CURDIR)/cfg/.env; \
		echo "Created $(CURDIR)/cfg/.env"; \
	fi

build: env
	$(MAKE) build-fsw
	$(MAKE) build-sim

build-fsw:
	docker run --rm -it -v $(CURDIR):$(CURDIR) --name "tryspace_fsw_build" -w $(CURDIR)/fsw --user $(shell id -u):$(shell id -g) --sysctl fs.mqueue.msg_max=10000 --ulimit rtprio=99 --cap-add=sys_nice $(BUILD_IMAGE_NAME) make -j build-fsw

build-gsw:

build-sim:
	docker run --rm -it -v $(CURDIR):$(CURDIR) --name "tryspace_sim_build" -w $(CURDIR)/simulith --user $(shell id -u):$(shell id -g) --sysctl fs.mqueue.msg_max=10000 --ulimit rtprio=99 --cap-add=sys_nice $(BUILD_IMAGE_NAME) make -j build-sim

debug: env
	docker run --rm -it -v $(CURDIR):$(CURDIR) --name "tryspace_fsw_debug" -w $(CURDIR) --user $(shell id -u):$(shell id -g) --sysctl fs.mqueue.msg_max=10000 --ulimit rtprio=99 --cap-add=sys_nice $(BUILD_IMAGE_NAME) /bin/bash

clean:
	$(MAKE) stop
	$(MAKE) clean-fsw
	$(MAKE) clean-gsw
	$(MAKE) clean-sim

clean-fsw:
	cd fsw && $(MAKE) clean

clean-gsw:
	

clean-sim:
	cd simulith && $(MAKE) clean

container:
	docker build -t $(BUILD_IMAGE_NAME) -f cfg/Dockerfile.base --build-arg USER_ID=$(shell id -u) --build-arg GROUP_ID=$(shell id -g) .

runtime: env
	$(MAKE) container
	cd $(CURDIR)/comp/demo/sim && $(MAKE) runtime
	cd $(CURDIR)/fsw && $(MAKE) runtime
	cd $(CURDIR)/simulith && $(MAKE) director && $(MAKE) server

start: env
	docker compose -f ./cfg/lab-compose.yml up

start-fsw:
	cd fsw && $(MAKE) start

start-gsw:


start-sim:
	cd simulith && $(MAKE) start

stop:
	docker compose -f ./cfg/lab-compose.yml down
