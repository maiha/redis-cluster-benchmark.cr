module Bench::Commands
  alias Command = DynamicCommand | StaticCommand
  module Core
    protected abstract def raws : Array(String)
    protected abstract def feed : Array(String)

    def name
      raws.first
    end

    def to_s(io : IO)
      io << raws.join(" ")
    end
  end

  RAND_INT = "__rand_int__"
  
  record StaticCommand, raws : Array(String) do
    include Core

    def feed : Array(String)
      raws
    end
  end

  record DynamicCommand, raws : Array(String), keyspace : Int32? do
    include Core

    def feed : Array(String)
      [name] + raws[1..-1].map{|s| s.gsub(/__rand_int__/) { rand_int } }
    end

    private def rand_int
      rand(keyspace || UInt32::MAX / 2)
    end
  end

  def self.parse(str, keyspace)
    str.split(",").map{|s|
      args = s.strip.split(/\s+/)
      if args.grep(/#{RAND_INT}/).any?
        DynamicCommand.new(args, keyspace)
      else
        StaticCommand.new(args)
      end
    }
  end
end
