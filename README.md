# pony-kv

A really simple but multi-core Key-Value store.

It is allowing concurrent access to the underlying storage engine for reads,
so read heavy use cases can take full advantage of all cores.

At the same time it ensures that writes always happen on the latest state,
so no write operation gets deleted during concurrent storage engine updates.

The underlying storage engine is a persistent hashmap.

Setting and deleting keys happens asynchronously,
so the client will get a result before the actual store or delete
on the storage engine will take place.

## Server

This KV store server is listening on TCP for connections.

It speaks the redis protocol, so it can be accessed by any redis client
e.g. redis-cli.



### Building and running

```
$ make
$ ./build/server -h localhost -p 65535
```

### Supported Redis Commands

* PING
* GET
* SET (EX, PX, NX, XX arguments are not supported)
* DEL

## Status

[![CircleCI](https://circleci.com/gh/mfelsche/pony-kv.svg?style=svg)](https://circleci.com/gh/mfelsche/pony-kv)

## Installation

* Install [pony-stable](https://github.com/ponylang/pony-stable)
* Update your `bundle.json`

```json
{ 
  "type": "github",
  "repo": "mfelsche/pony-kv"
}
```

* `stable fetch` to fetch your dependencies
* `use "pony-kv"` to include this package
* `stable env ponyc` to compile your application
