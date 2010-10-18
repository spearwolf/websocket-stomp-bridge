require "em-websocket"

module WsStompBridge
  module StompClient
    include EM::Protocols::Stomp

    # EM->Stomp callback
    def connection_completed
      connect :login => config.stomp.login, :passcode => config.stomp.passwd
    end

    # EM->Stomp callback
    def receive_msg(msg)
      case msg.command

      when "CONNECTED"
        logger.info "Established connection: stomp://#{WsStompBridge.config.stomp.host}:#{WsStompBridge.config.stomp.port}"

      when "MESSAGE"
        logger.debug "Received message: #{msg.inspect}"
        WsStompBridge::ChannelManager.channel(msg.header["destination"]).push(msg.body)
      
      else
        logger.warn "Unknown message type: #{msg.inspect}"
      end
    end

    def publish(opts)
      send(opts[:to], opts[:message])
    end
    
    def unsubscribe(queue)
      send_frame "UNSUBSCRIBE", :destination => queue
    end
    
    def subscribe_to(queue)
      if subscription[queue].nil?
        subscription[queue] = 1
        subscribe(queue)
        logger.info "Subscribed to message queue '#{queue}'"
      else
        subscription[queue] += 1
        if subscription[queue] == 1
          subscribe(queue)
          logger.info "Re-Subscribed to message queue '#{queue}'"
        else
          logger.debug "Set subscription counter for message queue '#{queue}' to #{subscription[queue]}"
        end
      end
    end

    def cancel_subscription(queue)
      if subscription[queue].nil?
        logger.warn "Oops .. couldn't cancel subscription to queue '#{queue}': there is no previous subscription!"
      elsif subscription[queue] == 1
        logger.info "Canceling subscription to message queue '#{queue}'"
        unsubscribe(queue)
        subscription[queue] = 0
      else
        subscription[queue] -= 1
        logger.debug "Set subscription counter for message queue '#{queue}' to #{subscription[queue]}"
      end
    end

    private

    def config; WsStompBridge.config; end
    def stomp; WsStompBridge.stomp; end
    def logger; WsStompBridge.logger; end

    def subscription
      @subscription ||= {}
    end
  end
end