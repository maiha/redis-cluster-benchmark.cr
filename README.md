# redis-cluster-benchmark

Benchmark utils for Redis Cluster that is inspired by `redis-benchmark`.

- compiled on crystal-0.18.7
- binary download: https://github.com/maiha/redis-cluster-benchmark.cr/releases

## Config

- See: `bench.toml`

```toml
[redis]
clusters = "127.0.0.1:7001,127.0.0.1:7002"  # at least one node
# password = "secret"

[bench]
requests = 100000  # number of requests for each commands
keyspace = 10000   # max number of key for `__rand_int__`
tests    = "set __rand_int__ __rand_int__"
after    = "set result/last __result__"
# after    = "rpush results __result__"
qps      = 5000
# debug = true

[report]
interval_sec = 1
verbose = true
```

## Run

```shell
% redis-cluster-benchmark bench.toml
=== set __rand_int__ __rand_int__ ===
17:19:52 [5.0%] 5002/100000 (4989.3 qps)
17:19:53 [10.0%] 10003/100000 (4996.1 qps)
...
17:20:11 [95.1%] 95086/100000 (5000.9 qps)
17:20:12 done 100000 in 20.8 sec (0.0)
SET: 5820.68 rps (OK: 100000, KO: 0)
```

- Algthough we sent 100,000 requests, only 10,000 keys are created due to `keyspace = 10000`.

```
% rcm -u :7001 info count
893550 [127.0.0.1:7001]  cnt(3334)
bd4456 [127.0.0.1:7002]  cnt(3330)
87b981 [127.0.0.1:7003]  cnt(3336)
```

- rcm: https://github.com/maiha/rcm.cr/releases


#### After Hook

- We can set after hook by `after` field in `bench` section.
- In above example, benchmark result has been set in redis via special keyword `__result__`.

```
% redis-cli -c -p 7001 get result/last
"1977.6 qps (OK:100000, KO:0) [02:53:26 +51s]"
```

- Of course, apending logs is good idea by `rpush`

```
after    = "rpush results __result__"
```

## Roadmap

#### 0.3
- [ ] After Hook

#### 0.4
- [ ] Reconnect after errors
- [ ] Multi Clients

#### 0.5
- [ ] Connection Setting (use `keep alive` or not)
- [ ] Protocol Setting (use `pipeline` or not)

## Contributing

1. Fork it ( https://github.com/maiha/redis-cluster-benchmark/fork )
2. Create your feature branch (git checkout -b my-new-feature)
3. Commit your changes (git commit -am 'Add some feature')
4. Push to the branch (git push origin my-new-feature)
5. Create a new Pull Request

## Contributors

- [maiha](https://github.com/maiha) maiha - creator, maintainer
