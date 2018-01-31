PONYC ?= ponyc
SERVER_SOURCES = $(shell find pony-kv/server -name "*.pony")
CLIENT_SOURCES = $(shell find pony-kv/client -name "*.pony")
TEST_SOURCES = $(shell find pony-kv/test -name "*.pony")
OPTIONAL_SOURCES = $(shell find pony-kv/optional -name "*.pony")

build/kv-server: build $(SERVER_SOURCES) $(OPTIONAL_SOURCES)
	$(PONYC) pony-kv/server -o build -p pony-kv --debug

build/kv-client: build $(CLIENT_SOURCES) $(OPTIONAL_SOURCES)
	$(PONYC) pony-kv/client -o build -p pony-kv --debug

build/test: build $(SERVER_SOURCES) $(CLIENT_SOURCES) $(OPTIONAL_SOURCES) $(TEST_SOURCES)
	$(PONYC) pony-kv/test -o build -p pony-kv --debug

build:
	mkdir build

test: build/test
	build/test

clean:
	rm -rf build

.PHONY: clean test
