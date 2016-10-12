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
    @errexit  = @config.bool("bench/errexit").as(Bool)
    @interval = @config.int?("report/interval_sec").as(Int32?)
    @verbose  = @config.bool("report/verbose").as(Bool)

    tests     = @config.str("bench/tests").as(String)
    @context  = Commands::Context.new(keyspace: @keyspace)
    @commands = Commands.parse(tests, @context)
    raise "No tests in `bench/tests`" if @commands.empty?

    @limitter = @config.int?("bench/qps").try{|qps| Limitter.new(qps: qps, verbose: @config.bool("bench/debug")) }
    @client = Redis::Cluster.new(@clusters, @password)
  end

  def run
    results = [] of String
    
    @commands.each do |cmd|
      verbose "=== #{cmd} ==="

      interval = (@interval || 3).seconds
      output   = (@verbose && !!@interval) ? @io : nil
      reporter = Periodical::Reporter.new(interval, @requests, io: output)
      
      @requests.times do |i|
        pause_for_next
        reporter.succ { execute(cmd) }
      end
      reporter.done
      show_summary(cmd, reporter.total)
      results << "%s : %s" % [cmd.name.upcase, reporter.total.summarize]
    end

    after(results.join("\n"))
  end

  private def execute(cmd)
    @client.command(cmd.feed)
  rescue err
    if @errexit
      msg = err.to_s
      puts @client.bootstraps.inspect.colorize.red
      puts msg.colorize.red
      exit -1
    else
      raise err
    end
  end

  private def pause_for_next
    @limitter.try(&.await)
  end

  private def verbose(msg)
    @io.puts msg if @verbose
  end

  private def show_summary(cmd, stat)
    msg = "%s: %s" % [cmd.name.upcase, stat.summarize]
    msg = msg.colorize.yellow if stat.ko > 0
    @io.puts msg

    if stat.errors.any?
      verbose "(ERRORS)"
      stat.errors.each do |err|
        verbose "  #{err}".colorize.yellow
      end
    end
  end

  def after(result)
    @config.str?("bench/after").try do |str|
      ctx = @context.copy({Commands::Context::RESULT => result})
      Commands.parse(str, ctx).each do |cmd|
        verbose "=== [AFTER] #{cmd} ==="
        @client.command(cmd.feed)
      end
    end
  end
end
