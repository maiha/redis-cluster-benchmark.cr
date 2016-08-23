require "../bench"

class Main
  include Opts

  VERSION = "0.1.0"
  PROGRAM = "redis-cluster-benchmark"
  ARGS    = "bench.toml"

  option quiet   : Bool, "-q", "Quiet. Just show query/sec values", false
  option version : Bool, "--version", "Print the version and exit", false
  option help    : Bool, "--help"   , "Output this help and exit" , false
  
  def run
    toml = TOML.parse_file(args.shift { die "config not found!" })
    Bench::Program.new(toml).run(quiet: quiet)
  end
end

Main.run
