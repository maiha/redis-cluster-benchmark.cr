class Bench::Program
  @commands : Array(Bench::Commands::Command)
  @limitter : Bench::Limitter?

  def initialize(@config : Config)
    @clusters = @config.str("redis/clusters").as(String)
    @password = @config.str?("redis/password").as(String?)
    @requests = @config.int("bench/requests").as(Int32)
    @keyspace = @config.int?("bench/keyspace").as(Int32?) || UInt32::MAX / 2
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
    io = STDOUT

    @commands.each do |cmd|
      if @verbose
        io.puts "=== #{cmd} ==="
      end
      reporter = Periodical::Reporter.new((@interval || 3).to_i32.seconds, @requests.to_i32, enable: @verbose && !!@interval, io: io)
      stat = Stats::Stat.new
      
      @requests.times do |i|
        execute(client, cmd, stat, reporter)
        pause_for_next
      end
      reporter.done
      Stats::Reporter.new(cmd, stat, io: io, verbose: @verbose).report
    end
  end

  private def report(str : String, io : IO = STDOUT)
      io << str
  end

  private def execute(client, cmd, stat, reporter, t1 = Time.now)
    client.command(cmd.feed)
    stat.ok!(Time.now - t1)
    reporter.ok!
  rescue err
    stat.ko!(Time.now - t1, err)
    reporter.ko!
  end

  private def pause_for_next
    @limitter.try(&.await)
  end
end
