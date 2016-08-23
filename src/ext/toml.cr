require "toml"

record TOML::Config,
  toml : Hash(String, TOML::Type) do

  def [](key)
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

class TOML::Path
  def initialize(toml : Hash(String, TOML::Type))
    @paths = Hash(String, TOML::Type).new
    build_path(toml, "")
  end

  ######################################################################
  ### Primary API
  
  def [](key)
    key = key.to_s
    @paths.fetch(key) { not_found(key) }
  end

  def []?(key)
    key = key.to_s
    @paths.fetch(key) { nil }
  end

  ######################################################################
  ### Syntax Sugar
  
  def str(key)
    self[key].as(String)
  end

  def str?(key)
    self[key]?.as(String?)
  end

  def int64(key)
    self[key].as(Int64)
  end

  def int64?(key)
    self[key]?.try(&.as(Int64))
  end

  def int(key)
    int64(key).to_i32.as(Int32)
  end

  def int?(key)
    int64?(key).try(&.to_i32.as(Int32))
  end

  def bool(key)
    if self[key]?
      self[key].as(Bool)
    else
      false
    end
  end

  ######################################################################
  ### Internal Functions
  
  protected def not_found(key)
    raise "toml[%s] is not found" % key
  end

  private def build_path(toml, path)
    case toml
    when Hash
      toml.each do |(key, val)|
        build_path(val, path.empty? ? key : "#{path}/#{key}")
      end
    else
      @paths[path] = toml
    end
  end
end
