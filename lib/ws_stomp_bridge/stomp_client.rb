require "em-websocket"

module WsStompBridge
  module StompClient
    include EM::Protocols::Stomp

    class << self

      def publish(msg)
        WsStompBridge.stomp.send(WsStompBridge.config.stomp.publish, msg) if WsStompBridge.stomp
      end
    end

    def connection_completed
      connect :login => WsStompBridge.config.stomp.login, :passcode => WsStompBridge.config.stomp.passwd
    end

    def receive_msg msg
      if msg.command == "CONNECTED"
        subscribe(queue)
        WsStompBridge.logger.info "Established subscription: stomp://#{WsStompBridge.config.stomp.host}:#{WsStompBridge.config.stomp.port}#{queue}"
      else
        WsStompBridge.channel.push(msg.body)
        WsStompBridge.logger.debug "[#{queue}] #{msg.body}"
      end
    end

    private

    def queue
      @queue ||= WsStompBridge.config.stomp.subscribe
    end
  end
end
