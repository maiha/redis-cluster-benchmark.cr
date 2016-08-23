module Periodical
  class Reporter
    delegate report, done, to: @impl

#    def initialize(@interval : Time::Span, total : (Int32 | Nil -> Int32), enable : Bool = true)
#      @total = total.is_a?(Nil -> Int32) ? total.call : total
    def initialize(@interval : Time::Span, @total : Int32, enable : Bool = true, io : IO = STDOUT)
      @impl = (enable && @total > 0) ? Impl.new(@interval, @total, io: io) : Nop.new
    end
  end

  class Nop
    def report(i : Int32)
    end

    def done
    end
  end

  class Impl
    def initialize(@interval : Time::Span, @total : Int32, @io : IO)
      @started_at = @reported_at = Time.now
      @report_count = 0
      @last_count = 0
      raise "#{self.class} expects @total > 0, bot got #{@total}" unless @total > 0
    end

    def report(cnt : Int32)
      now = Time.now
      return if now < @reported_at + @interval
      pcent = [cnt * 100.0 / @total, 100.0].min
      time = now.to_s("%H:%M:%S")
      qps = qps_string(cnt - @last_count, now - @reported_at)

      @io.puts "%s [%03.1f%%] %d/%d (%s)" % [time, pcent, cnt, @total, qps]
      @io.flush
      @last_count = cnt
      @reported_at = now
      @report_count += 1
    end

    def done
      now  = Time.now
      took = now - @started_at
      qps  = qps_string(@total, took)
      sec  = took.total_seconds
      time = now.to_s("%H:%M:%S")
      @io.puts "%s done %d in %.1f sec (%s)" % [time, @total, sec, qps]
    end

    private def qps_string(count, took : Time::Span)
      qps = count*1000.0 / took.total_milliseconds
      return "%.1f qps" % qps
    rescue
      return "--- qps"
    end
  end
end
