require_relative "channel_manager"

module WsStompBridge

  class ClientConnectionBase

    CM = WsStompBridge::ChannelManager

    attr_accessor :websocket
    attr_accessor :stomp

    def initialize
      @channels = {}
    end

    def id
      object_id
    end

    protected

    def subscribe_to(queue)
      unless @channels[queue]
        @channels[queue] = CM.channel(queue).subscribe do |msg|
          on_stomp_message(msg)
        end
      end
      use_stomp {|stomp| stomp.subscribe_to(queue) }
    end

    def unsubscribe(queue)
      if sid = @channels[queue]
        CM.channel(queue).unsubscribe(sid)
        @channels.delete(queue)
        use_stomp {|stomp| stomp.cancel_subscription(queue) }
      end
    end

    def unsubscribe_all
      @channels.each do |queue, sid|
        if queue && sid
          CM.channel(queue).unsubscribe(sid)
          use_stomp {|stomp| stomp.cancel_subscription(queue) }
        end
      end
      @channels = {}
    end

    def publish(queue, msg)
      use_stomp do |stomp|
        if msg && msg != ""
          stomp.publish :to => queue, :message => msg
          logger.debug "[#{id}] Published message '#{msg}' to queue '#{queue}'"
        else
          logger.warn "[#{id}] ClientConnection#publish: dropped message: msg is blank"
        end
      end
    end

    def send_to_client(msg)
      if websocket
        websocket.send(msg)
        logger.debug "[#{id}] Sent message '#{msg}' to WebSocket client"
      else
        logger.error "[#{id}] ClientConnection#send_to_client: couldn't send message: websocket is nil"
      end
    end
    
    def logger
      WsStompBridge.logger
    end

    # def on_websocket_connect
    # def on_websocket_message(msg)
    # def on_websocket_disconnect
    # def on_stomp_message(msg)

    private
    
    def use_stomp
      if stomp
        yield(stomp) if block_given?
      else
        logger.error "[#{id}] ClientConnection: stomp is nil"
      end
    end

  end
end