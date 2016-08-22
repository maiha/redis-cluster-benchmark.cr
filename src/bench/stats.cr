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
    
  def initialize(commands : Array(Command))
    @stats = Hash(Command, Stat).new
    commands.each do |cmd|
      @stats[cmd] = Stat.new
    end
  end

  def ok(cmd, span)
    @stats[cmd].ok!(span)
  end

  def ko(cmd, span, err)
    @stats[cmd].ko!(span, err)
  end

  def report(io : IO, verbose : Bool = true)
    @stats.each do |(cmd, stat)|
      if verbose
        report_stat_detail(io, cmd, stat)
      else
        report_stat_simple(io, cmd, stat)
      end
    end
  end

  private def report_stat_detail(io, cmd, stat)
    io << "#{cmd.name.upcase}: #{stat.rps} (#{stat.total})\n"
    io << "  OK: #{stat.ok} (#{stat.span})\n"
    io << "  KO: #{stat.ko}\n"
    stat.errors.each do |err|
      io << "  #{err}"
    end
  end

  private def report_stat_simple(io, cmd, stat)
    err = stat.errors.any? ? "(#{stat.errors.first(3).inspect})" : ""
    io << "#{cmd.name.upcase}: #{stat.rps} rps (ok: #{stat.ok}, ko: #{stat.ko})#{err}\n"
  end
end
