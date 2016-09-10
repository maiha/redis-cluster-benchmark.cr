class Bench::Config < TOML::Config
  property dump_on_error : Bool = false

  def merge!(verbose : Bool? = false)
    @paths["report/verbose"] = verbose if ! verbose.nil?
    return self
  end

  def not_found(key)
    pretty_dump if dump_on_error
    raise "toml[%s] is not found" % key
  end

  private def pretty_dump(io : IO = STDERR)
    io.puts "[config]"
    max = @paths.keys.map(&.size).max
    @paths.each do |(key, val)|
      io.puts "  %-#{max}s : %s" % [key, val]
    end
  end
end
