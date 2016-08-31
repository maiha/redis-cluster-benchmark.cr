# redis-cluster-benchmark [![Build Status](https://travis-ci.org/maiha/redis-cluster-benchmark.cr.svg?branch=master)](https://travis-ci.org/maiha/redis-cluster-benchmark.cr)

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

#### Error Reporting

```
12:00:26 [94.6%] 946044/1000000 (4993.2 qps) # KO: 109
12:00:27 [95.1%] 951045/1000000 (4992.1 qps) # KO: 270
12:00:28 [95.6%] 956046/1000000 (4991.9 qps) # KO: 110
12:00:29 [96.1%] 961047/1000000 (4994.8 qps)
12:00:30 [96.6%] 966048/1000000 (4994.4 qps)
12:00:31 [97.1%] 971049/1000000 (4990.4 qps)
12:00:32 [97.6%] 976050/1000000 (4992.0 qps)
12:00:33 [98.1%] 981051/1000000 (4991.3 qps)
12:00:34 [98.6%] 986052/1000000 (4997.0 qps)
12:00:35 [99.1%] 991053/1000000 (4995.3 qps)
12:00:36 [99.6%] 996054/1000000 (4993.2 qps)
12:00:36 done 1000000 in 201.9 sec (4953.0 qps) # KO: 818
SET: 4953.0 qps (OK:999182, KO:818) [11:57:15 +3m21s] # RedisError: OOM command not allowed when used
 memory > 'maxmemory'.
 (ERRORS)
   RedisError: OOM command not allowed when used memory > 'maxmemory'.
   === [AFTER] RPUSH results __result__ ===
```

## Roadmap

#### 0.4
- [x] Reconnect after errors
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
