require "./src/worker_pool"

class Mailman < Worker(String)
    @count = 0

    def process(workload : String)
        @count += 1
        puts "Worker##{@id}: Processing mail ##{@count} -> #{workload}"
        sleep 1.seconds
        puts "Worker##{@id}: Done with ##{@count}"
    end

end

fiber_pool = WorkerPool(String).new(10, 3) {|channel, id|
    Mailman.new(channel, id)
}

10.times do |i|
    fiber_pool.process("This is mail ##{i}")
end
puts("Finished pushing mails")

sleep 1200.milliseconds
fiber_pool.terminate

sleep 1.seconds
