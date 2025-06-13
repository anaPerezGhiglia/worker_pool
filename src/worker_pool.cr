class WorkerPool(A)

    def initialize(buffer_capacity : Int32, pool_size : Int32, &builder : (Channel(A), Int32) -> Worker(A))
        @channel = Channel(A).new(buffer_capacity)

        @workers = Array(Worker(A)).new(pool_size)
        pool_size.times do |idx|
            spawn do
                worker = builder.call(@channel, idx)
                # TODO: need to syncronize ?
                @workers << worker

                # allow all workers to get created before start processing
                Fiber.yield
                worker.start()
            end
        end
    end

    def process(workload : A)
        @channel.send workload
    end

    # TODO: think if it makes sense to do someting
    # with the elements that may never get processed
    # because the channel was closed before they got consumed
    def terminate()
        @channel.close
        @workers.each do |worker|
            worker.terminate
        end
    end

end


abstract class Worker(A)

    def initialize(@channel : Channel(A), @id : Int32)
        puts "Starting worker ##{@id}"
    end

    def start()
        @running = true
        while @running
            workload = @channel.receive
            process workload
        end
        puts "Worker##{@id}: bye!"
    end

    def terminate
        puts "Worker##{@id}: Finishing work.."
        @running = false
    end

    abstract def process(workload : A)
end

