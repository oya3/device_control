# coding: utf-8

class ICCardDevice
  attr_accessor :ws_conn
  attr_accessor :connect_signature
  def initialize
    # ここで本当のデバイスの初期化や接続処理を行う
    @connect_signature = nil
  end
  
  def read
    sleep(5)
    return "読み込んだカードはこれだすよ！！！"
  end
  
  def write(body)
    sleep(5)
    return 
  end
end
