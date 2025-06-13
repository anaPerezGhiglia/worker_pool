# WorkerPool

Minimalistic worker pool implementation

WorkerPool allows to split workload between concurrent workers in a bounded manner (it spawns a new fiber for each worker created)

Keep in mind that the pool is internally implemented with a BufferedChannel. This means that if the channel is full then the calling fiber will block until there is space for the new workload. The size of the buffer and the number of active workers is configurable so it can fit different needs.  

- `buffer_capacity` defines the capacity of the inner Channel.
- `pool_size` controls the # of workers (thus fibers) to initialize & have ready to process workload
