# redis-cluster-benchmark

Benchmark utils for Redis Cluster that is inspired by `redis-benchmark`.

## Usage

#### config

- See: `bench.toml`

```toml
[redis]
clusters = "127.0.0.1:7001,127.0.0.1:7002"  # at least one node

[bench]
requests = 10000
tests = "set __rand_int__ __rand_int__"

[report]
interval_sec = 3
# verbose = true
```

#### run

```shell
% redis-cluster-benchmark bench.toml
```

## Contributing

1. Fork it ( https://github.com/maiha/redis-cluster-benchmark/fork )
2. Create your feature branch (git checkout -b my-new-feature)
3. Commit your changes (git commit -am 'Add some feature')
4. Push to the branch (git push origin my-new-feature)
5. Create a new Pull Request

## Contributors

- [maiha](https://github.com/maiha) maiha - creator, maintainer
