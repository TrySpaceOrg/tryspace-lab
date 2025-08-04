# Makefile for TrySpace Lab development
.PHONY: all build build-fsw build-gsw build-sim build-cli cfg clean container debug real-clean runtime start stop cli

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
	$(MAKE) cfg

# Configure orchestrator (merges configs and updates active.yaml) using Docker
cfg:
	@echo "[Makefile] Running orchestrator to merge configs in Docker..."
	docker run --rm -v $(CURDIR):$(CURDIR) -w $(CURDIR)/cfg --user $(shell id -u):$(shell id -g) $(BUILD_IMAGE_NAME) python3 tryspace-orchestrator.py

build: env
	$(MAKE) build-fsw
	$(MAKE) build-sim

build-cli: env
	$(MAKE) container
	@for dir in $(CURDIR)/comp/*/cli ; do \
		if [ -f "$$dir/Makefile" ]; then \
			$(MAKE) -C "$$dir" runtime; \
		fi; \
	done
	cd $(CURDIR)/simulith && $(MAKE) director && $(MAKE) server

build-fsw:
	docker run --rm -it -v $(CURDIR):$(CURDIR) --name "tryspace_fsw_build" -w $(CURDIR)/fsw --user $(shell id -u):$(shell id -g) --sysctl fs.mqueue.msg_max=10000 --ulimit rtprio=99 --cap-add=sys_nice $(BUILD_IMAGE_NAME) make -j build-fsw

build-gsw:

build-sim:
	docker run --rm -it -v $(CURDIR):$(CURDIR) --name "tryspace_sim_build" -w $(CURDIR)/simulith --user $(shell id -u):$(shell id -g) $(BUILD_IMAGE_NAME) make -j build-sim

debug: env
	docker run --rm -it -v $(CURDIR):$(CURDIR) --name "tryspace_fsw_debug" -w $(CURDIR) --user $(shell id -u):$(shell id -g) --sysctl fs.mqueue.msg_max=10000 --ulimit rtprio=99 --cap-add=sys_nice $(BUILD_IMAGE_NAME) /bin/bash

clean:
	$(MAKE) stop
	$(MAKE) clean-cli
	$(MAKE) clean-fsw
	$(MAKE) clean-gsw
	$(MAKE) clean-sim

clean-cli:
	@for dir in $(CURDIR)/comp/*/cli ; do \
		if [ -f "$$dir/Makefile" ]; then \
			$(MAKE) -C "$$dir" clean; \
		fi; \
	done

clean-fsw:
	cd fsw && $(MAKE) clean

clean-gsw:
	

clean-sim:
	cd simulith && $(MAKE) clean

cli: env
	$(MAKE) build-cli
	docker compose -f ./cfg/cli-compose.yml up

container:
	docker build -t $(BUILD_IMAGE_NAME) -f cfg/Dockerfile.base --build-arg USER_ID=$(shell id -u) --build-arg GROUP_ID=$(shell id -g) .

runtime: env
	$(MAKE) container
	cd $(CURDIR)/comp/demo/sim && $(MAKE) runtime
	cd $(CURDIR)/fsw && $(MAKE) runtime
	cd $(CURDIR)/simulith && $(MAKE) director && $(MAKE) server

real-clean: clean
	docker ps -a --filter "name=tryspace-" -q | xargs -r docker rm -f
	docker images "tryspace-*" -q | xargs -r docker rmi

start: env
	docker compose -f ./cfg/lab-compose.yml up

start-fsw:
	cd fsw && $(MAKE) start

start-gsw:


start-sim:
	cd simulith && $(MAKE) start

stop:
	docker compose -f ./cfg/cli-compose.yml down
	docker compose -f ./cfg/lab-compose.yml down
	docker images -f "dangling=true" -q | xargs -r docker rmi

