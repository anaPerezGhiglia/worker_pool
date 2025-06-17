require "wait_group"

module WorkerPool
  class Pool(A) 

    def initialize(*, buffer_capacity : Int32, pool_size : Int32, &builder : (Channel(A), Int32) -> Worker(A))
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

    def process(workload : A)
      @channel.send workload
    end

    ## Closes channel so no new workloads can be enqueued
    ## workers will process all the already enqueued workload
    ## before terminating and ending fiber lifecycle
    def terminate
      @channel.close
    end

    ## Waits until all workers have finished their work
    def wait
      @wait_group.wait
    end
  end

  abstract class Worker(A)
    def initialize(@channel : Channel(A), @id : Int32)
      puts "Starting worker ##{@id}"
    end

    def start
      while workload = @channel.receive?
        begin
          process workload
        rescue ex
          on_error ex
        end
      end
      puts "Worker##{@id}: bye!"
    end

    abstract def process(workload : A)
    abstract def on_error(error)
  end
end
