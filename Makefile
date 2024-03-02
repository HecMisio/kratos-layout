NAME=$(shell basename `pwd`)
VERSION=$(shell git describe --tags --always)
INTERNAL_PROTO_FILES=$(shell find internal -name *.proto)
API_PROTO_FILES=$(shell find api -name *.proto)
GRPC_FILES=$(shell find api -name *.pb.go)
ERROR_PROTO_FILES=$(shell find api -name errors.proto)

.PHONY: init
# init env
init:
	go install google.golang.org/protobuf/cmd/protoc-gen-go@latest
	go install google.golang.org/grpc/cmd/protoc-gen-go-grpc@latest
	go install github.com/go-kratos/kratos/cmd/kratos/v2@latest
	go install github.com/google/gnostic/cmd/protoc-gen-openapi@latest

.PHONY: config
# generate internal proto
config:
	protoc --proto_path=./internal \
	       --proto_path=./third_party \
 	       --go_out=paths=source_relative:./internal \
	       $(INTERNAL_PROTO_FILES)

.PHONY: api
# generate api proto
api:
	protoc --proto_path=./api \
	       --proto_path=./third_party \
 	       --go_out=paths=source_relative:./api \
 	       --go-grpc_out=paths=source_relative:./api \
	       --validate_out=paths=source_relative,lang=go:./api \
	       $(API_PROTO_FILES) && \
    for file in $(GRPC_FILES); do \
	  protoc-go-inject-tag -input $$file; \
    done

.PHONY: errors
# generate errors proto
errors:
	protoc --proto_path=./api \
		   --proto_path=./third_party \
		   --go_out=paths=source_relative:./api \
		   --go-errors_out=paths=source_relative:./api \
		   $(ERROR_PROTO_FILES)

.PHONY: swag
# generate swagger files
swag:
	swag fmt && swag init -g ./cmd/server/main.go

.PHONY: build
# build
build:
	mkdir -p bin/ && go build -ldflags "-X main.Version=$(VERSION) -X main.Name=$(NAME)" -o ./bin/ ./...

.PHONY: run
# run
run:
	go run -ldflags "-X main.Version=$(VERSION) -X main.Name=$(NAME)" ./cmd/server/... -conf configs/config.yaml

.PHONY: all
# generate all
all:
	make api;
	make config;
	make errors;

# show help
help:
	@echo ''
	@echo 'Usage:'
	@echo ' make [target]'
	@echo ''
	@echo 'Targets:'
	@awk '/^[a-zA-Z\-\_0-9]+:/ { \
	helpMessage = match(lastLine, /^# (.*)/); \
		if (helpMessage) { \
			helpCommand = substr($$1, 0, index($$1, ":")-1); \
			helpMessage = substr(lastLine, RSTART + 2, RLENGTH); \
			printf "\033[36m%-22s\033[0m %s\n", helpCommand,helpMessage; \
		} \
	} \
	{ lastLine = $$0 }' $(MAKEFILE_LIST)

.DEFAULT_GOAL := help
