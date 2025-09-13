# ZephyrFS Protocol Buffer Makefile

# Directories
PROTO_DIR = protobuff
GEN_DIR = generated
RUST_OUT = $(GEN_DIR)/rust
GO_OUT = $(GEN_DIR)/go
TS_OUT = $(GEN_DIR)/typescript

# Proto files
PROTO_FILES = $(wildcard $(PROTO_DIR)/*.proto)

# Tools
PROTOC = protoc
RUST_PLUGIN = --rust_out=$(RUST_OUT) --rust-grpc_out=$(RUST_OUT)
GO_PLUGIN = --go_out=$(GO_OUT) --go-grpc_out=$(GO_OUT)
TS_PLUGIN = --ts_out=$(TS_OUT) --grpc-web_out=import_style=typescript,mode=grpcweb:$(TS_OUT)

.PHONY: all clean rust go typescript setup

all: setup rust go typescript

setup:
	@mkdir -p $(RUST_OUT) $(GO_OUT) $(TS_OUT)

rust: setup
	@echo "Generating Rust code from protobuf files..."
	@for proto in $(PROTO_FILES); do \
		$(PROTOC) --proto_path=$(PROTO_DIR) $(RUST_PLUGIN) $$proto; \
	done
	@echo "Rust protobuf generation complete"

go: setup
	@echo "Generating Go code from protobuf files..."
	@for proto in $(PROTO_FILES); do \
		$(PROTOC) --proto_path=$(PROTO_DIR) $(GO_PLUGIN) $$proto; \
	done
	@echo "Go protobuf generation complete"

typescript: setup
	@echo "Generating TypeScript code from protobuf files..."
	@for proto in $(PROTO_FILES); do \
		$(PROTOC) --proto_path=$(PROTO_DIR) $(TS_PLUGIN) $$proto; \
	done
	@echo "TypeScript protobuf generation complete"

clean:
	@echo "Cleaning generated files..."
	@rm -rf $(GEN_DIR)
	@echo "Clean complete"

install-deps:
	@echo "Installing protobuf compiler dependencies..."
	# Install protoc (platform-specific)
	@if command -v apt-get >/dev/null 2>&1; then \
		sudo apt-get update && sudo apt-get install -y protobuf-compiler; \
	elif command -v brew >/dev/null 2>&1; then \
		brew install protobuf; \
	elif command -v pacman >/dev/null 2>&1; then \
		sudo pacman -S protobuf; \
	else \
		echo "Please install protobuf compiler manually"; \
		exit 1; \
	fi
	# Install Rust protobuf plugins
	@cargo install protobuf-codegen protoc-gen-rust grpc-compiler
	# Install Go protobuf plugins
	@go install google.golang.org/protobuf/cmd/protoc-gen-go@latest
	@go install google.golang.org/grpc/cmd/protoc-gen-go-grpc@latest
	# Install TypeScript protobuf plugins
	@npm install -g protoc-gen-ts protoc-gen-grpc-web

validate:
	@echo "Validating protobuf files..."
	@for proto in $(PROTO_FILES); do \
		echo "Validating $$proto..."; \
		$(PROTOC) --proto_path=$(PROTO_DIR) --descriptor_set_out=/dev/null $$proto || exit 1; \
	done
	@echo "All protobuf files are valid"

docs:
	@echo "Generating protocol documentation..."
	@mkdir -p docs/generated
	@$(PROTOC) --proto_path=$(PROTO_DIR) --doc_out=docs/generated --doc_opt=html,index.html $(PROTO_FILES)
	@echo "Documentation generated in docs/generated/"

.PHONY: install-deps validate docs