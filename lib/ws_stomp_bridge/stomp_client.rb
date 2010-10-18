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
      if stomp
        stomp.send(opts[:to], opts[:message])
      else
        logger.error "Couldn't publish message '#{opts[:message]}' to queue '#{opts[:to]}': stomp is nil"
      end
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
          logger.info "Set subscription counter for message queue '#{queue}' to #{subscription[queue]}"
        end
      end
    end
    
    def unsubscribe(queu)
      logger.warn "TODO StompClient#unsubscribe"
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