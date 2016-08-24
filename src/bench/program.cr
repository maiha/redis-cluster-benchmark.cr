require "colorize"

class Bench::Program
  @commands : Array(Bench::Commands::Command)
  @limitter : Bench::Limitter?
  @io : IO = STDOUT

  def initialize(@config : Config)
    @clusters = @config.str("redis/clusters").as(String)
    @password = @config.str?("redis/password").as(String?)
    @requests = @config.int("bench/requests").as(Int32)
    @keyspace = @config.int?("bench/keyspace").as(Int32?) || (UInt32::MAX / 2).to_i32
    @interval = @config.int?("report/interval_sec").as(Int32?)
    @verbose  = @config.bool("report/verbose").as(Bool)

    tests     = @config.str("bench/tests").as(String)
    @context  = Commands::Context.new(keyspace: @keyspace)
    @commands = Commands.parse(tests, @context)
    raise "No tests in `bench/tests`" if @commands.empty?

    @limitter = @config.int?("bench/qps").try{|qps| Limitter.new(qps: qps, verbose: @config.bool("bench/debug")) }
  end

  def run
    client = Redis::Cluster.new(@clusters, @password)

    @commands.each do |cmd|
      verbose "=== #{cmd} ==="

      interval = (@interval || 3).seconds
      output   = (@verbose && !!@interval) ? @io : nil
      reporter = Periodical::Reporter.new(interval, @requests, io: output)
      
      @requests.times do |i|
        pause_for_next
        reporter.succ { client.command(cmd.feed) }
      end
      reporter.done
      show_summary(cmd, reporter.total)
    end
  end

  private def pause_for_next
    @limitter.try(&.await)
  end

  private def verbose(msg)
    @io.puts msg if @verbose
  end

  private def show_summary(cmd, stat)
    name = cmd.name.upcase
    msg  = "%s: %s (OK: %s, KO: %s)" % [name, stat.qps, stat.ok, stat.ko]
    msg += " (#{stat.errors.first})" if !@verbose && stat.errors.any?

    msg = msg.colorize.yellow if stat.ko > 0
    @io.puts msg

    if stat.errors.any?
      verbose "(ERRORS)"
      stat.errors.each do |err|
        verbose "  #{err}".colorize.yellow
      end
    end
  end
end
