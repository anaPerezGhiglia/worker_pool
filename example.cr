require "./src/worker_pool"

class Mailman < Worker(String)
  @count = 0
  @random = Random.new

  def process(workload : String)
    @count += 1
    puts "Worker##{@id}: Processing mail ##{@count} -> #{workload}"
    sleep 1.seconds
    if @random.next_bool
      raise "Ooops, something went wrong :("
    end
    puts "Worker##{@id}: Done with ##{@count}"
  end

  def on_error(error)
    puts("Worker##{@id}: Caught exception: #{error}")
  end
end

fiber_pool = WorkerPool(String).new buffer_capacity: 10, pool_size: 3 { |channel, id|
  Mailman.new(channel, id)
}

10.times do |i|
  fiber_pool.process("This is mail ##{i}")
end
puts("Finished pushing mails")

# We terminate it "quick" to evidence
# what happens when fiber_pool gets terminated
# with "pending" work (workloads enqueued but not processed)
sleep 800.milliseconds
fiber_pool.terminate

# wait until fiber_pool finishes processing
fiber_pool.wait
