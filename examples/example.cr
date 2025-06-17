require "../src/worker_pool"
require "log"

class Mailman < WorkerPool::Worker(String)
  @count = 0
  @random = Random.new

  def process(workload : String)
    @count += 1
    Log.info {"Worker##{@id}: Processing mail ##{@count} -> #{workload}"}
    sleep 1.seconds
    if @random.next_bool
      raise "Ooops, something went wrong :("
    end
    Log.info {"Worker##{@id}: Done with ##{@count}"}
  end

  def on_error(error)
    Log.info {"Worker##{@id}: Caught exception: #{error}"}
  end
end

Log.setup(:debug)
fiber_pool = WorkerPool::Pool(String).new buffer_capacity: 10, pool_size: 3 { |channel, id|
  Mailman.new(channel, id)
}

10.times do |i|
  fiber_pool.process("This is mail ##{i}")
end
Log.debug {"Finished pushing mails"}

# We terminate it "quick" to evidence
# what happens when fiber_pool gets terminated
# with "pending" work (workloads enqueued but not processed)
sleep 800.milliseconds
fiber_pool.terminate

# wait until fiber_pool finishes processing
fiber_pool.wait
