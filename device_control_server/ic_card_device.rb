# coding: utf-8
require 'fiddle/import'
require 'fiddle/types'

module PasoriAPI
  extend Fiddle::Importer
  dlload 'felicalib.dll'
  include Fiddle::BasicTypes
  include Fiddle::Win32Types

  MAX_SYSTEM_CODE = 8
  MAX_AREA_CODE = 16
  MAX_SERVICE_CODE = 256
  POLLING_ANY = 0xffff
  POLLING_EDY = 0xfe00
  POLLING_SUICA = 0x0003

  typealias 'pasori', 'void'
  typealias 'felica', 'void'
  typealias 'uint16', 'unsigned short'
  typealias 'uint8', 'unsigned char'

  typealias 'MAX_SERVICE_CODE', MAX_SERVICE_CODE
  
  Felica = struct( [
      "pasori *p", # PaSoRi ハンドル
      "uint16 systemcode", # システムコード
      "uint8 IDm[8]", # IDm
      "uint8 PMm[8]", # PMm
      # systemcode
      "uint8 num_system_code", # 列挙システムコード数
      "uint16 system_code[8]", # 列挙システムコード
      # area/service codes
      "uint8 num_area_code", # エリアコード数
      "uint16 area_code[16]", # エリアコード
      "uint16 end_service_code[16]", # エンドサービスコード
      "uint8 num_service_code", # サービスコード数
      "uint16 service_code[256]", # サービスコード
    ])

  extern 'pasori* pasori_open(char *)' # PaSoRi をオープンする 
  extern 'void pasori_close(pasori *)' # PaSoRi ハンドルをクローズする
  extern 'int pasori_init(pasori *)' # PaSoRi を初期化する
  extern 'felica* felica_polling(pasori *, uint16, uint8, uint8)' # FeliCa をポーリングする
  extern 'void felica_free(felica *)' # felica ハンドル解放
  extern 'void felica_getidm(felica *, uint8 *)' # IDm 取得
  extern 'void felica_getpmm(felica *, uint8 *)' # PMm 取得
#  extern 'int felica_read_without_encryption02(felica *, int, int, uint8, uint8 *)' # 暗号化されていないブロックを読み込む
#  extern 'int felica_write_without_encryption(felica *, int, uint8, uint8 *)' # 暗号化されていないブロックを書き込む
  extern 'felica* felica_enum_systemcode(pasori *)' # システムコードの列挙
  extern 'felica* felica_enum_service(pasori *, uint16)' # サービス/エリアコードの列挙

  def self.n2hs(value)
    ( ((value & 0xff) << 8) | ((value & 0xff00) >> 8) )
  end
  
end





class ICCardDevice
  attr_accessor :ws_conn
  attr_accessor :connect_signature
  
  def initialize
    # ここで本当のデバイスの初期化や接続処理を行う
    @connect_signature = nil
    @data = nil

    # pasori 接続
    pasori_ptr = PasoriAPI::pasori_open(0)
    PasoriAPI::pasori_init(pasori_ptr)
    # ベース読み込み
    base_ptr = nil
    60.times do
      base_ptr = PasoriAPI::felica_polling(pasori_ptr, PasoriAPI::POLLING_ANY, 0, 0)
      if !base_ptr.null?
        break
      end
      puts "カードかざせ!!!".encode('cp932')
      sleep(1)
    end
    # base_ptr.null?
    base = PasoriAPI::Felica.new(base_ptr)
    puts "IDm[#{base.IDm}]"
    puts "PMm[#{base.PMm}]"
    PasoriAPI::felica_free(base_ptr);
    
    # システムコード
    system_code_ptr = PasoriAPI::felica_enum_systemcode(pasori_ptr);
    system_code = PasoriAPI::Felica.new(system_code_ptr)
    puts "num_system_code[#{system_code.num_system_code}]"
    puts "system_code[#{system_code.system_code}]"
    
    (0..(system_code.num_system_code-1)).each do |index|
      printf "system_code[%04X]\n", PasoriAPI::n2hs(system_code.system_code[index])
      enum_service_ptr = PasoriAPI::felica_enum_service(pasori_ptr, PasoriAPI::n2hs(system_code.system_code[index]) )
      enum_service = PasoriAPI::Felica.new(enum_service_ptr)
      
      printf "num_area_code[%d]\n", enum_service.num_area_code
      (0..(enum_service.num_area_code-1)).each do |index2|
        printf "area[%04X - %04X]\n",enum_service.area_code[index2], enum_service.end_service_code[index2]
      end
      
      printf "num_service_code[%d]\n", enum_service.num_service_code
      # for (j = 0; j < f2->num_service_code; j++) do
      #   uint16 service = f2->service_code[j];
      #   printserviceinfo(service);
      
      #   for (k = 0; k < 255; k++) do
      #     uint8 data[16];
      
      #     if (felica_read_without_encryption02(f2, service, 0, (uint8)k, data))
      #         break;
      #     end
      
      #     printf("%04X:%04X ", service, k);
      #     hexdump(data, 16);
      #     printf("\n");
      #   end
      # end
      # printf("\n");
      # felica_free(f2);
      
      PasoriAPI::felica_free(enum_service_ptr);
    end
    
    
    
    PasoriAPI::felica_free(system_code_ptr);
    
    PasoriAPI::pasori_close(pasori_ptr);
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
