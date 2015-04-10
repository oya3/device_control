# coding: cp932
require "em-websocket"
require "pry"
connections = []
EM::WebSocket.start(host: "172.17.10.58", port: 3001) do |ws_conn|
  ws_conn.onopen do
    # 接続してきたコネクションを格納
    connections << ws_conn
    # binding.pry
  end
  
  ws_conn.onmessage do |message|
    # 全てのコネクションに対してメッセージを送信
    connections.each{|conn| conn.send(message) }
  end
  puts "EM::WebSocket loop."
end

puts "end"
