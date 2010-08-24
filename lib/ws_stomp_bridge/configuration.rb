require "yaml"
require "erb"
require "ostruct"

module WsStompBridge
  class Configuration

    def initialize(cfg, prefix = '', parent = nil)
      @config = cfg
      @prefix = prefix.to_s.upcase
      @parent = parent
    end

    def self.load(file, prefix = '')
      Configuration.new(YAML::load(ERB.new(IO.read(file)).result), prefix)
    end

    def keys
      @config.keys
    end

    def method_missing(name, *args)
      if name.to_s =~ /(.*)=$/
        set($1, args.first)
      else
        get(name)
      end
    end

    def env_name(name)
      name = name.to_s.upcase
      if @parent
        "#{@parent.env_name(@prefix)}_#{name}"
      else
        @prefix.length == 0 ? name : "#{@prefix}_#{name}"
      end
    end

    def [](name)
      get(name)
    end

    private

    def get(name)
      value = ENV[env_name(name)]
      unless value
        value = @config[name.to_s]
        return @config[name.to_s] = Configuration.new(value, name, self) if value.is_a? Hash
      end
      value
    end

    def set(name, value)
      @config[name] = value
    end
  end
end