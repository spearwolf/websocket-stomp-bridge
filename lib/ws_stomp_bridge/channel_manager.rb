require "em-websocket"

module WsStompBridge

  module ChannelManager
    extend self

    def channel(name)
      # (@channels ||= {})[name] ||= EM::Channel.new
      @channels ||= {}
      if @channels[name].nil?
        mutex.synchronize {
          @channels[name] = EM::Channel.new
        }
      end
      return @channels[name]
    end
    
    private
    
    def mutex
      @mutex ||= Mutex.new
    end
  end
end
