record Bench::Config,
  toml : Hash(String, TOML::Type) do

  def [](key)
    config(key)
  end

  private def config(key)
    obj = toml
    path = [] of String
    key.split("/").each do |k|
      path << k
      case obj
      when Nil
        raise "config[%s] is not found" % path.join("/")
      when Hash
        obj = obj.fetch(k) { nil }
      else
        raise "config[%s] is not hash" % path.join("/")
      end
    end
    return obj
  end
end
