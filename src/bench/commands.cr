module Bench::Commands
  alias Command = DynamicCommand | StaticCommand

  RAND_INT = "__rand_int__"
  
  record StaticCommand, raws : Array(String) do
    def name
      raws.first
    end

    def feed : Array(String)
      raws
    end
  end

  record DynamicCommand, raws : Array(String), keyspace : Int64? do
    def name
      raws.first
    end

    def args
      raws[1..-1].map{|s|
        s.gsub(/__rand_int__/) { rand_int }
      }
    end

    def feed : Array(String)
      [name] + args
    end

    private def rand_int
      rand(keyspace || UInt64::MAX / 2)
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
