class Bench::Program
  @commands : Array(Bench::Commands::Command)
    
  def initialize(toml)
    @config = Config.new(toml)

    @clusters = @config["redis/clusters"].as(String)
    @password = @config["redis/password"].as(String?)
    @requests = @config["bench/requests"].as(Int64)
    @keyspace = @config["bench/keyspace"].as(Int64?)
    @commands = Commands.parse(@config["bench/tests"].as(String), @keyspace)
    @stats = Stats.new(@commands)

    raise "tests not found" if @commands.empty?
  end

  def run(quiet : Bool)
    client = Redis::Cluster.new(@clusters, @password)

    @requests.times do |i|
      cmd = @commands[i % @commands.size]
      execute(client, cmd)
    end

    @stats.report(STDOUT, verbose: !quiet)
  end

  private def execute(client, cmd, t1 = Time.now)
    client.command(cmd.feed)
    t2 = Time.now
    @stats.ok(cmd, t2-t1)
  rescue err
    t2 = Time.now
    @stats.ko(cmd, t2-t1, err)
  end
end
