require "em-websocket"

module WsStompBridge
  module StompClient
    include EM::Protocols::Stomp

    # class << self
    # 
    #   def publish(msg)
    #     stomp.send(config.stomp.publish, msg) if stomp
    #   end
    #   
    #   def config; WsStompBridge.config; end
    #   def stomp; WsStompBridge.stomp; end
    #   def logger; WsStompBridge.logger; end
    # end

    # EM->Stomp callback
    def connection_completed
      connect :login => config.stomp.login, :passcode => config.stomp.passwd
    end

    # EM->Stomp callback
    def receive_msg(msg)
      if msg.command == "CONNECTED"
        subscribe(queue)
        logger.info "Established subscription: stomp://#{WsStompBridge.config.stomp.host}:#{WsStompBridge.config.stomp.port}#{queue}"
      else
        # TODO
        WsStompBridge.channel.push(msg.body)
        logger.debug "[#{queue}] #{msg.body}"
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
    # def config; self.config; end
    # def stomp; self.stomp; end
    # def logger; self.logger; end

    def queue
      @queue ||= config.stomp.subscribe
    end
  end
end