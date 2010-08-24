class EventMachine::WebSocket::Connection
  alias_method :orig_receive_data, :receive_data

  def receive_data(data)
    if data.index("<policy-file-request/>") == 0
      send_data <<POLICY
<?xml version="1.0" encoding="UTF-8"?>
<cross-domain-policy xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:noNamespaceSchemaLocation="http://www.adobe.com/xml/schemas/PolicyFileSocket.xsd">
<allow-access-from domain="#{WsStompBridge.config.flash_policy.allow_access_from.domain}" to-ports="#{WsStompBridge.config.flash_policy.allow_access_from.ports}" secure="false" />
<site-control permitted-cross-domain-policies="all" />
</cross-domain-policy>
\000
POLICY
    else
      orig_receive_data(data)
    end
  end
end
