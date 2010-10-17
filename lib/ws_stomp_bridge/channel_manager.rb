require "em-websocket"

module WsStompBridge

  module ChannelManager
    extend self

    def channel(name)
      (@channels ||= {})[name] ||= EM::Channel.new
    end
  end
end
