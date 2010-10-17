require_relative "channel_manager"

module WsStompBridge

  class ClientConnectionBase

    CM = WsStompBridge::ChannelManager

    attr_accessor :websocket
    attr_accessor :stomp

    def initialize
      @channels = {}
    end

    protected

    def subscribe_to(queue)
      unless @channels[queue]
        @channels[queue] = CM.channel(queue).subscribe do |msg|
          on_stomp_message(msg)
        end
      end
      # TODO stomp >> subscribe
    end

    def unsubscribe(queue)
      # TODO stomp >> unsubscribe
      if sid = @channels[queue]
        CM.channel(queue).unsubscribe(sid)
        @channels.delete(queue)
      end
    end

    def unsubscribe_all
      @channels.each do |queue, sid|
        # TODO stomp >> unsubscribe
        CM.channel(queue).unsubscribe(sid) if queue && sid
      end
      @channels = {}
    end

    def publish(queue, msg)
      if stomp
        if msg && msg != ""
          stomp.publish :to => queue, :message => msg
          logger.debug "published message to queue '#{queue}'"
        else
          logger.warn "ClientConnection#publish: dropped message: msg is blank"
        end
      else
        logger.warn "ClientConnection#publish: couldn't publish message: stomp is nil"
      end
    end

    def send_to_client(msg)
      if websocket
        websocket.send(msg)
        logger.debug "sent message to websocket client"
      else
        logger.warn "ClientConnection#send_to_client: couldn't send message: websocket is nil"
      end
    end
    
    def logger
      WsStompBridge.logger
    end

    # def on_websocket_connect
    # def on_websocket_message(msg)
    # def on_websocket_disconnect
    # def on_stomp_message(msg)
  end

  class ClientConnection < ClientConnectionBase

    def on_websocket_connect
      subscribe_to '/queue/public'
    end

    def on_websocket_message(msg)
      publish '/queue/worker', msg
    end

    def on_websocket_disconnect
      #unsubscribe '/queue/public'
      unsubscribe_all
    end

    def on_stomp_message(msg)
      send_to_client(msg)
    end
  end
end
