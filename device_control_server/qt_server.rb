# coding: utf-8
$LOAD_PATH.unshift(File.expand_path(File.dirname(__FILE__)))

require 'em-websocket'
require 'Qt4'
require 'server_widget'
require 'ic_card_device'

require 'pry'

# ICカードデバイス制御
ic_card_device = ICCardDevice.new

app = Qt::Application.new(ARGV)
widget = ServerWidget.new
widget.device = ic_card_device
widget.show
# app.exec

# メインスレッド
EM.run do
  # IC カード読み込み
  ic_card_read = proc do
    # 別スレッドで実行される
    ic_card_device.read
  end
  
  # IC カード読み込み完了
  ic_card_read_callback = proc do |res|
    # メインスレッドで実行される
    ic_card_device.ws_conn.send(res)
  end
  
  # app.exec
  EM.add_periodic_timer(0.01) do
    app.process_events
    # qt 終了イベントを受信して、EM::stop とかやらんとスレッド残る。ゾンビ化する。。。きっと
  end
  
  connections = Hash.new # 接続情報保持用
  EM::WebSocket.start(host: "172.17.10.58", port: widget.parameter['contents']['port']) do |ws_conn|
    # 接続受信
    ws_conn.onopen do
      puts "event[onopen] : open #{ws_conn.signature}"
      params = Hash.new
      params[:ws_conn] = ws_conn # コネクション情報は全部保持
      params[:alive_timer] = set_alive_timer(ws_conn) # n分間接続なければ切断
      connections[ws_conn.signature] = params
    end
    
    # メッセージ受信
    ws_conn.onmessage do |message|
      disp_message = "#{Time.now}:#{message}"
      params = connections[ws_conn.signature]
      params[:alive_timer].cancel # alive_timer クリア
      params[:ws_conn].send("カード情報はあほあほです") # 接続してきたやつに応答を返す。
      
      # TODO: デバイスが空いてたらばICカード読み込みか書き込み(factory+state_machineでやりたいね。。。)
      widget.ui['label_msg'].text = "カードかざしてくれ！"
      widget.ui['listWidget_log'].addItem(disp_message)
      ic_card_device.ws_conn = ws_conn
      EM.defer(ic_card_read, ic_card_read_callback)
      
      params[:alive_timer] = set_alive_timer(ws_conn)
    end
    
    # 切断受信
    ws_conn.onclose do
      puts "event[onclose] : socket close signature[#{ws_conn.signature}]"
      # ws_conn.close
    end
    
  end
  
  # 生存タイマを張る
  def set_alive_timer(ws_conn)
    p = EM::Timer.new(1*60) do
      puts "timeout : socket close signature[#{ws_conn.signature}]"
      ws_conn.close
    end
    return p
  end

end


