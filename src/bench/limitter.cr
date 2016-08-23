class Bench::Limitter
  @until : Time
  @count : Int32

  def initialize(@qps : Int32, @verbose : Bool = false)
    @count = 0
    @until = Time.now + 1.second
  end

  def await
    loop do
      if @count < @qps
        succ!
        return
      end

      wait_interval = (@until - Time.now).total_seconds
      if wait_interval <= 0
        reset!
        return
      end

      if @verbose
        STDERR.puts "### QPS Limit! (wait: #{wait_interval} sec) ###"
      end
      sleep wait_interval
    end
  end

  private def succ!
    @count += 1
    reset! if @until < Time.now
  end

  private def reset!
    @count = 0
    @until = Time.now + 1.second
  end
end
