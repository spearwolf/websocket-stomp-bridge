A Simple WebSocket To Stomp Bridge
==================================

                                                 +-----------+
    +------------------+                         | websocket |                     +----------------------+
    | websocket client |<<<---[ WebSocket ]--->>>|  stomp    |<<<---[ STOMP ]--->>>| stomp message broker |
    |   ( browser )    |                         |   bridge  |                     |     ( activemq )     |
    +------------------+                         +-----------+                     +----------------------+
                                                       |
                                 ______________________V_____________________
                                 |                                          |
                                 |  class WsStompBridge::ClientConnection   |
                                 |                                          |
                                 |      def on_websocket_connect            |
                                 |          subscribe_to '/queue/public'    |
                                 |      end                                 |
                                 |                                          |
                                 |      def on_websocket_message(msg)       |
                                 |          publish '/queue/worker', msg    |
                                 |      end                                 |
                                 |                                          |
                                 |      def on_websocket_disconnect         |
                                 |          #unsubscribe '/queue/public'    |
                                 |          unsubscribe_all                 |
                                 |      end                                 |
                                 |                                          |
                                 |      def on_stomp_message(msg)           |
                                 |          send_to_client(msg)             |
                                 |      end                                 |
                                 |  end                                     |
                                 |                                          |
                                 ============================================

© 2010 by Wolfger Schramm <wolfger@spearwolf.de>
