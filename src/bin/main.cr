require "../bench"
require "../options"
require "colorize"

class Main
  include Options

  VERSION = "0.1.0"
  PROGRAM = "redis-cluster-benchmark"

  option quiet   : Bool, "-q", "Quiet. Just show query/sec values", false
  option version : Bool, "--version", "Print the version and exit", false
  option help    : Bool  , "--help" , "Output this help and exit" , false
  
  usage <<-EOF
    #{PROGRAM} version #{VERSION}

    Usage: #{PROGRAM} bench.conf
    EOF

  def run
    args                        # kick parse!
    quit(usage) if help
    quit("#{PROGRAM} #{VERSION}") if version

    toml = TOML.parse_file(args.shift { die "config not found!" })
    Bench::Program.new(toml).run(quiet: quiet)
    
  rescue err
    STDERR.puts err.to_s.colorize(:red)
    exit 1
  end
end

Main.new.run
