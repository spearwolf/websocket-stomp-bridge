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
        subscribe(queue)
        logger.info "Established subscription: stomp://#{WsStompBridge.config.stomp.host}:#{WsStompBridge.config.stomp.port}#{queue}"

      when "MESSAGE"
        # logger.debug "got message: #{msg.inspect}"
        WsStompBridge::ChannelManager.channel(msg.header["destination"]).push(msg.body)
      
      else
        logger.warn "unknown message type: #{msg.inspect}"
      end
    end

    def publish(opts)
      if stomp
        stomp.send(opts[:to], opts[:message])
      else
        logger.error "coudn't publish message '#{opts[:message]}' to queue '#{opts[:to]}': stomp is nil"
      end
    end

    private

    def config; WsStompBridge.config; end
    def stomp; WsStompBridge.stomp; end
    def logger; WsStompBridge.logger; end

    # XXX obsolete
    def queue
      @queue ||= config.stomp.subscribe
    end
  end
end