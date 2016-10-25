require "../bench"

class Main
  include Opts

  VERSION = "0.3.6"
  PROGRAM = "redis-cluster-benchmark"
  ARGS    = "bench.toml"

  option errexit : Bool, "-e", "Exit on first error", false
  option verbose : Bool, "-v", "Verbose output to show rps", false
  option version : Bool, "--version", "Print the version and exit", false
  option help    : Bool, "--help"   , "Output this help and exit" , false
  
  def run
    toml = TOML.parse_file(args.shift { die "config not found!" })
    conf = Bench::Config.new(toml)
    conf.merge!(verbose: verbose, errexit: errexit) if verbose
    conf.dump_on_error = true

    Bench::Program.new(conf).run
  end
end

Main.run
