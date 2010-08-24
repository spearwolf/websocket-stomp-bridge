# Created 2010/04/02 by wolfger@spearwolf.de
require "em-websocket"
require "yaml"
require "erb"
require "logger"
require_relative "ws_stomp_bridge/configuration"
require_relative "ws_stomp_bridge/flash_policy"

module WsStompBridge
  extend self

  attr_accessor :stomp

  def config
    @config ||= WsStompBridge::Configuration.new({})
  end

  def configure(path)
    @config = WsStompBridge::Configuration.load(path)
  end

  def channel
    @channel ||= EM::Channel.new
  end

  def sid
    @sid ||= {}
  end

  def logger
    @logger ||= Logger.new(STDOUT)
  end

  def logger=(logger)
    @logger = logger
  end

  module StompClient  # {{{
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
  # }}}

  def start
    EM.run {
      # WebSocket server {{{
      EventMachine::WebSocket.start(:host => WsStompBridge.config.websocket.bind, :port => WsStompBridge.config.websocket.port, :debug => false) do |ws|

        ws.onopen do
          sid[ws] = channel.subscribe {|msg| ws.send(msg) }
          logger.debug "new websocket connection [ws/#{sid[ws]}]"
        end

        ws.onclose do
          if sid[ws]
            channel.unsubscribe(sid[ws])
            logger.debug "[ws/#{sid[ws]}] closed websocket connection"
            sid[ws] = nil
          end
        end

        ws.onmessage do |msg|
          StompClient.publish(msg)
          logger.debug "[ws/#{sid[ws]}] received websocket message: #{msg}"
        end
      end
      # }}}

      EM.connect(config.stomp.host, config.stomp.port, StompClient) {|stomp_client| WsStompBridge.stomp = stomp_client }

      logger.info "WebSocket/Stomp bridge started on ws://#{config.websocket.bind}:#{config.websocket.port}/"
    }
  end
end

