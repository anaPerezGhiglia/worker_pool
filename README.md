# worker_pool

Minimalistic worker pool implementation

WorkerPool allows to split workload between concurrent workers in a bounded manner (it spawns a new fiber for each worker created)

## Installation

1. Add the dependency to your `shard.yml`:

   ```yaml
   dependencies:
     worker_pool:
       github: anaperezghiglia/worker_pool
   ```

2. Run `shards install`

## Usage

Keep in mind that the pool is internally implemented with a BufferedChannel. This means that if the channel is full then the calling fiber will block until there is space for the new workload. The size of the buffer and the number of active workers is configurable so it can fit different needs.  

- `buffer_capacity` defines the capacity of the inner Channel.
- `pool_size` controls the # of workers (thus fibers) to initialize & have ready to process workload

instantiate a new worker_pool

```crystal
require "worker_pool"

worker_pool = WorkerPool::Pool(String).new buffer_capacity: 10, pool_size: 3 { |channel, id|
  Mailman.new(channel, id)
}
```

process workload

```crystal
  worker_pool.process("This is an example")
```

Explore [examples directory](./examples) for more detailed examples

## Development

TODO: Write development instructions here

## Contributing

1. Fork it (<https://github.com/your-github-user/worker_pool/fork>)
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request

## Contributors

- [Ana Perez Ghiglia](https://github.com/your-github-user) - creator and maintainer
