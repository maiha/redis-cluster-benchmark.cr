require "option_parser"
require "./macros"
require "colorize"

module Opts
  class OptionError < Exception
  end

  @args : Array(String)?

  macro expect_error(klass)
    begin
      {{yield}}
    rescue err : {{klass.id}}
      die err.to_s
    end
  end
            
  macro def args : Array(String)
    begin
      @args ||= option_parser.parse(ARGV)
      return @args.not_nil!
    rescue err : ArgumentError | Opts::OptionError | OptionParser::Exception
      die err.to_s
    end
  end

  macro option(name, long, desc, default)
    var {{name}}, {{default}}

    def register_option_{{name.var.id}}(parser)
      {% if long.stringify =~ /[\s=]/ %}
        {% if name.type.stringify == "Int64" %}
          parser.on({{long}}, "{{desc.id}} (default: {{default.id}}).") {|x| self.{{name.var}} = x.to_i64}
        {% elsif name.type.stringify.starts_with?("Int32") %}
          parser.on({{long}}, "{{desc.id}} (default: {{default.id}}).") {|x| self.{{name.var}} = x.to_i32}
        {% elsif name.type.stringify == "Int16" %}
          parser.on({{long}}, "{{desc.id}} (default: {{default.id}}).") {|x| self.{{name.var}} = x.to_i16}
        {% elsif name.type.stringify =~ /::Nil$/ %}
          parser.on({{long}}, "{{desc.id}}.") {|x| self.{{name.var}} = x}
        {% else %}
          parser.on({{long}}, "{{desc.id}} (default: {{default.id}}).") {|x| self.{{name.var}} = x}
        {% end %}
      {% else %}
        parser.on({{long}}, "{{desc.id}}.") {self.{{name.var}} = true}
      {% end %}
    end
  end

  macro option(name, short, long, desc, default)
    var {{name}}, {{default}}

    def register_option_{{name.var.id}}(parser)
      {% if long.stringify =~ /[\s=]/ %}
        {% if name.type.stringify == "Int64" %}
          parser.on({{short}}, {{long}}, "{{desc.id}} (default: {{default.id}}).") {|x| self.{{name.var}} = x.to_i64}
        {% elsif name.type.stringify == "Int32" %}
          parser.on({{short}}, {{long}}, "{{desc.id}} (default: {{default.id}}).") {|x| self.{{name.var}} = x.to_i32}
        {% elsif name.type.stringify == "Int16" %}
          parser.on({{short}}, {{long}}, "{{desc.id}} (default: {{default.id}}).") {|x| self.{{name.var}} = x.to_i16}
        {% elsif name.type.stringify =~ /::Nil$/ %}
          parser.on({{short}}, {{long}}, "{{desc.id}}.") {|x| self.{{name.var}} = x}
        {% else %}
          parser.on({{short}}, {{long}}, "{{desc.id}} (default: {{default.id}}).") {|x| self.{{name.var}} = x}
        {% end %}
      {% else %}
         parser.on({{short}}, {{long}}, "{{desc}}.") {self.{{name.var}} = true}
      {% end %}
    end
  end

  macro options(*names)
    {% for name in names %}
      option_{{name.id.stringify.id}}
    {% end %}
  end

  @option_parser : OptionParser?
  
  protected def option_parser
    @option_parser ||= new_option_parser
  end

  macro def new_option_parser : OptionParser
    OptionParser.new.tap{|p|
      {% for name in @type.methods.map(&.name.stringify) %}
        {% if name =~ /\Aregister_option_/ %}
          {{name.id}}(p)
        {% end %}
      {% end %}
    }
  end

  macro usage_args(str)
    protected def usage_args
      {{str}}
    end
  end

  macro version(str)
    protected def version
      {{str}}
    end
  end

  macro program(str)
    protected def program
      {{str}}
    end
  end

  PROGRAM = "#{$0}".split("/").last
  VERSION = "unknown"
  ARGS    = ""
  USAGE   = <<-EOF
    {{program}} version {{version}}

    Usage: {{program}} {{args}}

    Options:
    {{options}}
    EOF

  protected def die(reason : String)
    STDERR.puts usage
    STDERR.puts ""
    STDERR.puts reason.colorize(:red)
    exit -1
  end

  protected def exit(message : String)
    STDOUT.puts message
    exit 0
  end

  macro included
    def self.run
      main = new
      main.args                        # kick parse!
      main.exit(main.usage) if main.help
      main.exit("#{PROGRAM} #{VERSION}") if main.version
      main.run
    rescue err
      STDERR.puts err.to_s.colorize(:red)
      exit 1
    end

    def usage
      USAGE.gsub(/\{{program}}/, PROGRAM).gsub(/\{{version}}/, VERSION).gsub(/\{{args}}/, ARGS).gsub(/\{{options}}/, new_option_parser.to_s)
    end
  end
end
