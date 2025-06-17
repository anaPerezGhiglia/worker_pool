require "log"
require "wait_group"

module WorkerPool
  VERSION = "0.1.0"

  class Pool(A)
    Log = ::Log.for(self)

    # Creates a new `Pool` instance.
    # It spawns as many fiber as specified by *pool_size*.
    # Each spawned fiber instantiates and start a new `Worker`
    def initialize(*, buffer_capacity : Int32, pool_size : Int32, &builder : (Channel(A), Int32) -> Worker(A))
      Log.debug { "Starting new Pool with buffer_capacity: #{buffer_capacity} & pool_size: #{pool_size}" }

      @channel = Channel(A).new(buffer_capacity)

      @wait_group = WaitGroup.new(pool_size)
      pool_size.times do |idx|
        spawn do
          worker = builder.call(@channel, idx)
          # allow all workers to get created before start processing
          Fiber.yield
          worker.start
        ensure
          @wait_group.done
        end
      end
    end

    # Registers new wokload to be processed by the Pool
    def process(workload : A)
      @channel.send workload
    end

    # Closes the pool so it does not accept new workloads for processing.
    # However, the pool remains operative until workers finish processing
    # all the workload enqueued before `terminate` was called
    def terminate
      @channel.close
    end

    # Waits until all workers have finished
    # (there are no more active Worker fibers)
    def wait
      @wait_group.wait
    end
  end

  # This class defines a simple forever-running Worker.
  # The implementations of this abstract class will only
  # have to define the `process` and `on_error` methods to have
  # a simple but robust Worker
  abstract class Worker(A)
    Log = ::Log.for(self)

    def initialize(@channel : Channel(A), @id : Int32)
      Log.debug { "Starting worker ##{@id}" }
    end

    # Starts a new workload consumer that will be kept alive
    # as long as the channel is open
    def start
      while workload = @channel.receive?
        begin
          process workload
        rescue ex
          on_error ex
        end
      end
      Log.debug { "Worker##{@id}: bye!" }
    end

    # This method will get called each time
    # the worker processes a new workload
    abstract def process(workload : A)

    # This method will get called whenever an error
    # raises when processing a new workload
    abstract def on_error(error)
  end
end
