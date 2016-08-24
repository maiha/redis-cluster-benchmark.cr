module Bench::Commands
  alias Command = DynamicCommand | StaticCommand
  alias Mapping = Hash(String, String)

  class Context
    RAND_INT = "__rand_int__"

    delegate keys, to: @map
    
    def initialize(@map : Mapping = Mapping.new, keyspace : Int32? = nil)
      @map[RAND_INT] = keyspace.to_s if keyspace
    end

    def copy(map : Mapping)
      self.class.new(@map.merge(map))
    end

    def apply(s : String)
      @map.each do |(key, val)|
        case key
        when RAND_INT
          s = s.gsub(RAND_INT) { rand(val.to_i) }
        else
          s = s.gsub(key, val.to_s)
        end
      end
      return s
    end
  end
  
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
    
  record StaticCommand, raws : Array(String) do
    include Core

    def feed : Array(String)
      raws
    end
  end

  record DynamicCommand, raws : Array(String), ctx : Context do
    include Core

    def feed : Array(String)
      [name] + raws[1..-1].map{|s| ctx.apply(s)}
    end
  end

  def self.parse(str, ctx : Context)
    str.split(",").map{|s|
      args = s.strip.split(/\s+/)
      if str =~ /(#{ctx.keys.join("|")})/
        DynamicCommand.new(args, ctx)
      else
        StaticCommand.new(args)
      end
    }
  end
end
