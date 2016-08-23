class Bench::Program
  @commands : Array(Bench::Commands::Command)

  def initialize(@config : Config)
    @clusters = @config["redis/clusters"].as(String)
    @password = @config["redis/password"].as(String?)
    @requests = @config["bench/requests"].as(Int64).to_i32.as(Int32)
    @keyspace = @config["bench/keyspace"].as(Int64?)
    @interval = @config["report/interval_sec"].as(Int64?)
    @verbose  = @config["report/verbose"].as(Bool)
    @commands = Commands.parse(@config["bench/tests"].as(String), @keyspace)
    @stats = [] of Stats
    raise "tests not found" if @commands.empty?
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
end
