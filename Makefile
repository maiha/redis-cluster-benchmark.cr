SHELL = /bin/bash
LINK_FLAGS = --link-flags "-static" -D without_openssl
PROGS = redis-cluster-benchmark

.PHONY : all static compile spec clean bin test
.PHONY : ${PROGS}

all: static

test: spec compile static version

static: bin ${PROGS}

bin:
	@mkdir -p bin

redis-cluster-benchmark: src/bin/main.cr
	crystal build --release $^ -o bin/$@ ${LINK_FLAGS}

spec:
	crystal spec -v

compile:
	@for x in src/bin/*.cr ; do\
	  crystal build "$$x" -o /dev/null ;\
	done

clean:
	@rm -rf bin

version:
	./bin/redis-cluster-benchmark --version
