PONYC ?= ponyc
SERVER_SOURCES = $(shell find pony-kv/server -name "*.pony")
CLIENT_SOURCES = $(shell find pony-kv/client -name "*.pony")
SERVER_TEST_SOURCES = $(shell find pony-kv/server/test -name "*.pony")
TEST_SOURCES = $(shell find pony-kv/test -name "*.pony")

build/pony-kv: build $(SERVER_SOURCES)
	stable env $(PONYC) pony-kv/server --bin-name=pony-kv -o build -p pony-kv --debug

build/pony-kv-client: build $(CLIENT_SOURCES)
	stable env $(PONYC) pony-kv/client -o build -bin-name=pony-kv-client -p pony-kv --debug

build/server/test: build $(SERVER_SOURCES) $(SERVER_TEST_SOURCES)
	stable env $(PONYC) pony-kv/server/test -o build/server -p pony-kv --debug

build/test: build $(SERVER_SOURCES) $(CLIENT_SOURCES) $(TEST_SOURCES)
	stable env $(PONYC) pony-kv/test -o build -p pony-kv --debug

deps:
	stable fetch

build:
	mkdir build

test: build/test build/server/test
	build/test
	build/server/test

clean:
	rm -rf build

.PHONY: clean test deps
