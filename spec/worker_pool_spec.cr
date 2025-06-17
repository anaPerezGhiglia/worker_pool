require "./spec_helper"

class TestWorker < WorkerPool::Worker(String)
  getter last_workload : String | Nil
  getter last_error : Exception | Nil

  def process(workload)
    @last_workload = workload
  end

  def on_error(error)
    @last_error = error
  end
end

class TestFailWorker < WorkerPool::Worker(String)
  getter last_workload : String | Nil
  getter last_error : Exception | Nil
  property should_fail = false
  def process(workload)
    if should_fail
      raise "Ooops! Received #{workload}"
    end
    @last_workload = workload
  end

  def on_error(error)
    @last_error = error
  end
end

describe WorkerPool do
  create_new_test_worker = Proc(Channel(String), Int32, TestWorker).new { |channel, id| TestWorker.new(channel, id)}

  describe WorkerPool::Pool do
    it "closes the inner channel on #terminate" do
      pool = WorkerPool::Pool(String).new(buffer_capacity: 1, pool_size: 1, &create_new_test_worker)
      pool.terminate

      pool.@channel.closed?.should eq(true)
    end
  end

  describe WorkerPool::Worker do
    it "calls #process on every value received through the channel" do
      channel = Channel(String).new()
      worker = TestWorker.new(channel, 0)
      spawn do
        worker.start()
      end
      Fiber.yield      

      values = ["first", "second", "third", "last"]
      values.each do |value|
        channel.send(value)
        # we need to give the worker time 
        # to be able to consume the value
        Fiber.yield
        worker.last_workload.should eq(value)
      end
    end
    
    it "calls #on_error every time process raises" do
      channel = Channel(String).new()
      worker = TestFailWorker.new(channel, 0)
      spawn do
        worker.start()
      end
      Fiber.yield      

      channel.send("first")
      Fiber.yield
      worker.last_error.should be_nil # since the process call should not have failed
      
      worker.should_fail = true

      values = ["Boom", "BOOM", "tic, tac...boom"]
      values.each do |value|
        channel.send(value)
        # we need to give the worker time 
        # to be able to consume the value
        Fiber.yield
        worker.last_error.should_not be_nil
        worker.last_error.not_nil!.message.should eq("Ooops! Received #{value}")
      end
    end
  end
end
