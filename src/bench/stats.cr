class Bench::Stats
  include Commands

  class Stat
    getter ok, ko, errors, span

    def initialize(@ok : Int64 = 0_i64, @ko : Int64 = 0_i64, @errors : Set(String) = Set(String).new, @span : Time::Span = Time::Span::Zero)
    end

    def rps
      "%.2f" % (ok / span.total_seconds) rescue "---"
    end

    def total
      @ok + @ko
    end
    
    def ok!(span)
      @ok += 1
      @span += span
    end

    def ko!(span, err)
      @ko += 1
      @errors << (err.message || err.class.name).to_s
    end
  end

  class Reporter
    def initialize(@cmd : Command, @stat : Stat, @io : IO = STDOUT, @verbose : Bool = true)
    end

    def report
      if @verbose
        report_stat_detail
      else
        report_stat_simple
      end
    end

    private def report_stat_detail
      @io << "#{@cmd.name.upcase}: #{@stat.rps} rps (ok: #{@stat.ok}, ko: #{@stat.ko})\n"
      @stat.errors.each do |err|
        @io << "  #{err}"
      end
    end

    private def report_stat_simple
      err = @stat.errors.any? ? "(#{@stat.errors.first(3).inspect})" : ""
      @io << "#{@cmd.name.upcase}: #{@stat.rps} rps (ok: #{@stat.ok}, ko: #{@stat.ko})#{err}\n"
    end
  end
end
