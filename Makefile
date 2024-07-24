NASM=nasm
GCC=gcc
LD=ld
CFLAGS=-nostdlib -static -m64
DEBUG_FLAGS=-g

SRC=src
OBJ=assemblywebserver.o

##@ General

.PHONY: all
all: help

.PHONY: mk-dirs
mk-dirs: ## Create the necessary directories
	mkdir -p dist

##@ Help
.PHONY: help
help: ## Display this help message
	@awk 'BEGIN {FS = ":.*##"; printf "\nUsage:\n  make \033[36m<target>\033[0m\n"} /^[a-zA-Z_0-9-]+:.*?##/ { printf "  \033[36m%-15s\033[0m %s\n", $$1, $$2 } /^##@/ { printf "\n\033[1m%s\033[0m\n", substr($$0, 5) } ' $(MAKEFILE_LIST)

##@ Build
.PHONY: build
build: $(OBJ) ## Build the project to a binary
	$(LD) $(LDFLAGS) -o dist/assemblywebserver dist/$^

.PHONY: build-debug
build-debug: CFLAGS += $(DEBUG_FLAGS)
build-debug: $(OBJ) ## Build the project with debug symbols
	$(LD) $(LDFLAGS) -o dist/assemblywebserver-debug dist/$^

##@ Run
.PHONY: start
start: ## Start the built binary
	./dist/assemblywebserver

.PHONY: start-debug
start-debug: ## Start the built binary with debug symbols
	gdb ./dist/assemblywebserver-debug

%.o: $(SRC)/%.asm
	$(NASM) -f elf64 -g -F dwarf -o dist/$@ $<

##@ Clean
.PHONY: clean
clean: ## Clean build artifacts
	rm -f dist/$(OBJ) dist/assemblywebserver dist/assemblywebserver-debug
