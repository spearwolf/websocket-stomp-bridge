# Created 2010/04/02 by wolfger@spearwolf.de
require "em-websocket"
require "yaml"
require "erb"
require "logger"
require_relative "ws_stomp_bridge/configuration"
require_relative "ws_stomp_bridge/flash_policy"
require_relative "ws_stomp_bridge/stomp_client"
require_relative "ws_stomp_bridge/client_connection"

module WsStompBridge
  extend self
  
  WSB = WsStompBridge

  attr_accessor :stomp

  def config
    @config ||= WSB::Configuration.new({})
  end

  def configure(path)
    @config = WSB::Configuration.load(path)
  end

  def create_client_connection(ws)
    client = WSB::ClientConnection.new
    client.websocket = ws
    client.stomp = stomp
    clients[ws] = client
    logger.debug "New websocket connection: #{client.id}"
    client.on_websocket_connect
  end

  def destroy_client_connection(ws)
    if client = client_connection(ws)
      client.on_websocket_disconnect
      logger.debug "[#{client.id}] Disconnected!"
      @clients.delete(ws)
    end
  end

  def client_connection(ws)
    clients[ws]
  end

  def clients
    @clients ||= {}
  end

  def logger
    @logger ||= Logger.new(STDOUT)
  end

  def logger=(logger)
    @logger = logger
  end

  def start
    EM.run {
      EventMachine::WebSocket.start(:host => WSB.config.websocket.bind,
                                    :port => WSB.config.websocket.port,
                                    :debug => false) do |ws|
        ws.onopen { create_client_connection(ws) }
        ws.onclose { destroy_client_connection(ws) }
        ws.onmessage {|msg| client_connection(ws).on_websocket_message(msg) }
      end

      EM.connect(config.stomp.host, config.stomp.port, StompClient) do |stomp_client|
        WsStompBridge.stomp = stomp_client
      end

      logger.info "WebSocket/Stomp bridge started on ws://#{config.websocket.bind}:#{config.websocket.port}/"
    }
  end
end
