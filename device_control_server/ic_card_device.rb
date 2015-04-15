# coding: utf-8

class ICCardDevice
  attr_accessor :ws_conn
  attr_accessor :connect_signature
  def initialize
    # ここで本当のデバイスの初期化や接続処理を行う
    @connect_signature = nil
    @data = nil
  end
  
  def set_data(data)
    @data = data
  end

  def clear_data
    @data = nil
  end
  
  def read
    send_data = <<'EOS'
# coding: utf-8
content-type: ic_card
content-version: 0.1

contents:
  description: "標準的なカード 000"
  read_status: 1 # 0:読み込み成功, 1:読み込み失敗
  contents:
EOS
    # 60 sec 読み込み待ちする
    60.times do
      if !@data.nil?
        send_data = @data
        break
      end
      sleep(1)
    end
    return send_data
  end
  
  def write(body)
    # dummy...
    sleep(5)
    return 
  end
end
