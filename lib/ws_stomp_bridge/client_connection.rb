require_relative "client_connection_base"

module WsStompBridge

  class ClientConnection < ClientConnectionBase

    def on_websocket_connect
      subscribe_to '/queue/public'
    end

    def on_websocket_message(msg)
      publish '/queue/worker', msg
    end

    def on_websocket_disconnect
      # unsubscribe '/queue/public'
      unsubscribe_all
    end

    def on_stomp_message(msg)
      send_to_client(msg)
    end
  end
end
