require "colorize"

module Periodical
  class StatusCounter
    getter offset, count, index, ok, ko, errors

    @stopped_at : Time?

    def initialize(@total : Int32, @index : Int32 = 0, @ok : Int32 = 0, @ko : Int32 = 0, @errors : Set(String) = Set(String).new, @color : Bool = true, @span : Time::Span = Time::Span::Zero)
      @started_at = Time.now
      @count = 0
    end

    def next
      done!
      StatusCounter.new(@total, @index)
    end

    def ok!(span)
      @index += 1
      @count += 1
      @ok += 1
      @span += span
    end
    
    def ko!(err)
      @index += 1
      @count += 1
      @ko += 1
      @errors << (err.message || err.class.name).to_s
    end
    
    def done!
      @stopped_at ||= Time.now
    end

    def done?
      !! @stopped_at
    end

    def status
      err = ko > 0 ? "# KO: #{ko}" : ""
      now = @stopped_at || Time.now
      hms = now.to_s("%H:%M:%S")
      if done?
        msg = "%s done %d in %.1f sec (%s) %s" % [hms, @total, sec, qps, err]
      else
        msg = "%s [%03.1f%%] %d/%d (%s) %s" % [hms, pct, @index, @total, qps, err]
      end
      colorize(msg)
    end

    def spent_hms
      h,m,s,_ = spent.to_s.split(/[:\.]/)
      h = h.to_i
      m = m.to_i
      s = s.to_i
      String.build do |io|
        io << "#{h}h" if h > 0
        io << "#{m}m" if m > 0
        io << "#{s}s" if s > 0
      end
    end
    
    def summarize
      String.build do |io|
        hms = @started_at.to_s("%H:%M:%S")
        t1  = @started_at.epoch
        t2  = stopped_at.epoch
        io << "%s (OK:%s, KO:%s) [%s +%s](%d - %d)" % [qps, ok, ko, hms, spent_hms, t1, t2]
        io << " # #{errors.first}" if errors.any?
      end
    end
    
    def pct
      [@index * 100.0 / @total, 100.0].min
    end

    def spent(now = @stopped_at || Time.now)
      now - @started_at
    end

    def sec
      spent.total_seconds
    end

    def qps(now = @stopped_at || Time.now)
      "%.1f qps" % (@count*1000.0 / spent.total_milliseconds)
    rescue
      "--- qps"
    end

    def stopped_at
      if @stopped_at.nil?
        raise "not stopped yet"
      end
      @stopped_at.not_nil!
    end

    private def colorize(msg)
      if ko > 0
        msg.colorize.yellow
      else
        msg
      end
    end
  end
  
  class Reporter
    getter total

    def initialize(@interval : Time::Span, max : Int32, @io : IO? = STDOUT)
      @total   = StatusCounter.new(max)
      @current = StatusCounter.new(max)
      raise "#{self.class} expects max > 0, bot got #{max}" unless max > 0
    end

    def succ
      t1 = Time.now
      yield
      span = Time.now - t1
      @current.ok!(span)
      @total.ok!(span)
    rescue err
      @current.ko!(err)
      @total.ko!(err)
    ensure
      report
    end

    def report
      if @current.spent > @interval
        @io.try(&.puts @current.status).try(&.flush)
        @current = @current.next
      end
    end

    def done
      @current.done!
      @total.done!
      @io.try(&.puts @total.status)
    end
  end
end
