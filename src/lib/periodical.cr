require "colorize"

module Periodical
  class Reporter
    delegate ok!, ko!, done, to: @impl

#    def initialize(@interval : Time::Span, total : (Int32 | Nil -> Int32), enable : Bool = true)
#      @total = total.is_a?(Nil -> Int32) ? total.call : total
    def initialize(@interval : Time::Span, @total : Int32, enable : Bool = true, io : IO = STDOUT)
      @impl = (enable && @total > 0) ? Impl.new(@interval, @total, io: io) : Nop.new
    end
  end

  class StatusCounter
    property offset, count, index, ok, ko, color

    def initialize(@total : Int32, @index : Int32 = 0, @ok : Int32 = 0, @ko : Int32 = 0, @color : Bool = true)
      @started_at = Time.now
      @count = 0
    end

    def next
      StatusCounter.new(@total, @index)
    end

    def ok!
      @index += 1
      @count += 1
      @ok += 1
    end
    
    def ko!
      @index += 1
      @count += 1
      @ko += 1
    end
    
    def took(now = Time.now)
      now - @started_at
    end

    def sec
      took.total_seconds
    end

    def qps
      qps = count*1000.0 / took.total_milliseconds
      return "%.1f" % qps
    rescue
      return "---"
    end

    def progress
      time  = Time.now.to_s("%H:%M:%S")
      pcent = [@index * 100.0 / @total, 100.0].min
      err   = ko > 0 ? "# KO: #{ko}" : ""
      msg   = "%s [%03.1f%%] %d/%d (%s) %s" % [time, pcent, @index, @total, qps, err]
      colorize(msg)
    end

    private def colorize(msg)
      if ko > 0
        msg.colorize.yellow
      else
        msg
      end
    end

    def done
      @index = @total
      time = Time.now.to_s("%H:%M:%S")
      "%s done %d in %.1f sec (%s)" % [time, @total, sec, qps]
    end
  end
  
  class Nop
    macro method_missing(call)
    end
  end

  class Impl
    def initialize(@interval : Time::Span, @goal : Int32, @io : IO)
      @whole   = StatusCounter.new(@goal)
      @current = StatusCounter.new(@goal)
      raise "#{self.class} expects @goal > 0, bot got #{@goal}" unless @goal > 0
    end

    def ok!
      @current.ok!
      report
    end

    def ko!
      @current.ko!
      report
    end

    def report
      if @current.took > @interval
        @io.puts @current.progress
        @io.flush
        @current = @current.next
      end
    end

    def done
      @io.puts @whole.done
    end
  end
end
