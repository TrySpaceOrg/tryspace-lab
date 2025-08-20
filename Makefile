# Makefile for TrySpace Lab development
.PHONY: build clean clean-cache clean-cli clean-fsw clean-gsw clean-sim cfg cli container debug fsw gsw help mold sim start stop uninstall

# Build image name
export BUILD_IMAGE ?= tryspaceorg/tryspace-lab:0.0.0

# Common paths
CFG_DIR := $(CURDIR)/cfg

# Commands
build: cfg
	$(MAKE) sim
	$(MAKE) fsw
	$(MAKE) gsw

cfg: container
	docker run --rm -v $(CURDIR):$(CURDIR) -w $(CURDIR)/cfg --user $(shell id -u):$(shell id -g) $(BUILD_IMAGE) python3 tryspace-orchestrator.py

clean:
	$(MAKE) stop
	@if docker image inspect $(BUILD_IMAGE) >/dev/null 2>&1; then \
		$(MAKE) clean-cli; \
		$(MAKE) clean-fsw; \
		$(MAKE) clean-gsw; \
		$(MAKE) clean-sim; \
		docker volume ls -q --filter "name=gsw-data" | xargs -r docker volume rm; \
		docker volume ls -q --filter "name=simulith_ipc" | xargs -r docker volume rm; \
	else \
		echo "Docker image $(BUILD_IMAGE) does not exist. Skipping clean subcommands."; \
	fi

clean-cache:
	docker builder prune -f

clean-cli:
	@for dir in $(CURDIR)/comp/*/cli ; do \
		if [ -f "$$dir/Makefile" ]; then \
			$(MAKE) -C "$$dir" clean; \
		fi; \
	done

clean-fsw:
	cd fsw && $(MAKE) clean

clean-gsw:
	cd gsw && $(MAKE) clean

clean-sim:
	@for dir in $(CURDIR)/comp/*/sim ; do \
		if [ -d "$$dir" ] && [ -f "$$dir/Makefile" ]; then \
			$(MAKE) -C "$$dir" clean; \
		fi; \
	done
	cd simulith && $(MAKE) clean

cli: cfg
	$(MAKE) container
	$(MAKE) sim
	@for dir in $(CURDIR)/comp/*/cli ; do \
        if [ -f "$$dir/Makefile" ]; then \
            $(MAKE) -C "$$dir" runtime; \
        fi; \
    done
	docker compose -f ./cfg/cli-compose.yaml up

container: cfg/Dockerfile.base
	@command -v docker >/dev/null 2>&1 || { echo "Error: docker is not installed or not in PATH."; exit 1; }
	docker build -t $(BUILD_IMAGE) -f cfg/Dockerfile.base --build-arg USER_ID=$(shell id -u) --build-arg GROUP_ID=$(shell id -g) .

debug: cfg
	docker run --rm -it -v $(CURDIR):$(CURDIR) --name "tryspace_fsw_debug" -w $(CURDIR) --user $(shell id -u):$(shell id -g) --sysctl fs.mqueue.msg_max=10000 --ulimit rtprio=99 --cap-add=sys_nice $(BUILD_IMAGE) /bin/bash
	
fsw: cfg
	cd $(CURDIR)/fsw && $(MAKE) runtime

gsw: cfg
	cd $(CURDIR)/gsw && $(MAKE) runtime

mold:
	@if [ "$(COMP)" = "" ]; then \
		echo "Error: COMP parameter is required"; \
		echo "Usage: make mold COMP=<name>"; \
		echo "Example: make mold COMP=my_sensor"; \
		exit 1; \
	fi
	python3 $(CFG_DIR)/tryspace-comp-mold.py "$(COMP)"

help:
	@echo "Usage: make <target>"
	@echo "Targets:"
	@echo "  build         - Build the full runtime environment"
	@echo "  cfg           - Run orchestrator to configure environment"
	@echo "  cli           - Build CLI and start CLI services"
	@echo "  clean         - Remove build artifacts and stop services"
	@echo "  clean-cache   - Clean Docker build cache (frees significant disk space)"
	@echo "  clean-cli     - Clean CLI components"
	@echo "  clean-fsw     - Clean FSW components"
	@echo "  clean-gsw     - Clean GSW components"
	@echo "  clean-sim     - Clean simulation components"
	@echo "  container     - Build the Docker container"
	@echo "  debug         - Start a debug shell in the container"
	@echo "  fsw           - Build FSW"
	@echo "  gsw           - Build GSW"
	@echo "  mold          - Create new component from demo template (Usage: make mold COMP=<name>)"
	@echo "  sim           - Build Simulith and component simulators"
	@echo "  start         - Start lab services"
	@echo "  stop          - Stop lab and CLI services, clean up Docker images"
	@echo "  uninstall     - Remove containers, images, volumes, and networks"

sim: cfg
	@for dir in $(CURDIR)/comp/*/sim ; do \
		if [ -d "$$dir" ] && [ -f "$$dir/Makefile" ]; then \
			echo "Building component in $$dir"; \
			$(MAKE) -C "$$dir" build; \
		fi; \
	done
	cd $(CURDIR)/simulith && $(MAKE) director && $(MAKE) server

start: cfg
	docker compose -f ./cfg/lab-compose.yaml up

stop:
	docker compose -f ./cfg/cli-compose.yaml down --remove-orphans
	docker compose -f ./cfg/lab-compose.yaml down --remove-orphans
	docker images -f "dangling=true" -q | xargs -r docker rmi
	@echo ""
	@echo "To cleanup Docker build cache, run: make clean-cache"
	@echo "To cleanup everything Docker, run: docker system prune -a"

uninstall: clean clean-cache
	rm -f $(CFG_DIR)/active.yaml $(CFG_DIR)/build.yaml 
	docker ps -a --filter "name=tryspace-" -q | xargs -r docker rm -f
	docker images "tryspace-*" -q | xargs -r docker rmi
	docker volume ls -q --filter "name=gsw-data" | xargs -r docker volume rm
	docker volume ls -q --filter "name=simulith_ipc" | xargs -r docker volume rm
	docker network ls -q --filter "name=tryspace-net" | xargs -r docker network rm
	docker network ls -q --filter "name=cfg_tryspace-net" | xargs -r docker network rm
	@echo ""
	@echo "To cleanup everything docker even unrelated to TrySpace: "
	@echo "  docker system prune -a"
	@echo ""
