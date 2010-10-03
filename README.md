a simple websocket to stomp bridge
==================================

                                                 +-----------+
    +------------------+                         | websocket |                     +--------------+
    | websocket client |<<<---[ WebSocket ]--->>>|  stomp    |<<<---[ STOMP ]--->>>| stomp server |
    |   ( browser )    |                         |   bridge  |                     | ( activemq ) |
    +------------------+                         +-----------+                     +--------------+


© 2010 by Wolfger Schramm <wolfger@spearwolf.de>
