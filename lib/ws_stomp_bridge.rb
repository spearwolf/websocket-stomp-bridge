# Created 2010/04/02 by wolfger@spearwolf.de
require "em-websocket"
require "yaml"
require "erb"
require "logger"
require_relative "ws_stomp_bridge/configuration"
require_relative "ws_stomp_bridge/flash_policy"
require_relative "ws_stomp_bridge/stomp_client"

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

