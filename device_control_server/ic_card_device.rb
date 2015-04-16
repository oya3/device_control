# coding: utf-8
require 'fiddle/import'
require 'fiddle/types'
require 'yaml'

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
  extern 'int felica_read_without_encryption02(felica *, int, int, uint8, uint8 *)' # 暗号化されていないブロックを読み込む
  # extern 'int felica_write_without_encryption(felica *, int, uint8, uint8 *)' # 暗号化されていないブロックを書き込む
  extern 'felica* felica_enum_systemcode(pasori *)' # システムコードの列挙
  extern 'felica* felica_enum_service(pasori *, uint16)' # サービス/エリアコードの列挙

  def self.n2hs(value)
    ( ((value & 0xff) << 8) | ((value & 0xff00) >> 8) )
  end
  
end

class ICCardDevice
  SERVICE_SUICA_HISTORY = 0x090f
  

  attr_accessor :ws_conn
  attr_accessor :connect_signature
  
  def initialize
    # ここで本当のデバイスの初期化や接続処理を行う
    @connect_signature = nil
    @data = nil
    
    # @history = Array.new
    # pasori_connect
    # pasori_base_read
    # pasori_history_read
    # pasori_disconnect
    # json = create_history_json
    # puts json.encode('cp932')
    # exit 0
  end
  
  def set_data(data)
    @data = data
  end

  def clear_data
    @data = nil
  end
  
  def read
    send_data = <<'EOS'
:content_type: ic_history
:content_version: 0.1
:contents:
  status: 1 # 0:読み込み成功, 1:読み込み失敗
EOS
    @history = Array.new
    @idm_pmm = Hash.new
    pasori_connect
    pasori_base_read
    pasori_history_read
    pasori_disconnect
    # 成功しかありえないことにしておく。
    json = create_history_json
    return json
  end
  
  def write(body)
    # dummy...
    sleep(5)
    return 
  end

  def pasori_connect
    # pasori 接続
    @pasori_ptr = PasoriAPI::pasori_open(0)
    pasori_res = nil
    60.times do
      pasori_res = PasoriAPI::pasori_init(@pasori_ptr)
      if pasori_res == 0
        return true # 接続
      end
      puts 'ERROR(#{pasori_res}): PaSoRiが異常。きっと接続されてない。確認しやがれ!!'.encode('cp932')
      sleep(1)
    end
    return false # 接続失敗
  end
  
  def pasori_base_read
    # ベース読み込み
    @base_ptr = nil
    60.times do
      @base_ptr = PasoriAPI::felica_polling(@pasori_ptr, PasoriAPI::POLLING_ANY, 0, 0)
      if !@base_ptr.null?
        base = PasoriAPI::Felica.new(@base_ptr)
        @idm_pmm[:idm] = base.IDm
        @idm_pmm[:pmm] = base.PMm
        puts "IDm[#{base.IDm}]"
        puts "PMm[#{base.PMm}]"
        return true
      end
      puts "ERROR: カードかざせ!!!".encode('cp932')
      sleep(1)
    end
    return false
  end
  
  def create_history_json
    ## coding: utf-8
    # content-type: ic_log
    # content-version: 0.1
    
    # contents:
    #   description: "PaSoRiを使って読んだ内容"
    #   read_status: 1 # 0:読み込み成功, 1:読み込み失敗
    #   contents:
    yaml = Hash.new
    yaml[:content_type] = 'history'
    yaml[:content_version] = 0.1
    contents = Hash.new
    yaml[:contents] = contents
    contents[:status] = 0
    
    idm = @idm_pmm[:idm].collect {|item| sprintf("%02x",item) }
    pmm = @idm_pmm[:pmm].collect {|item| sprintf("%02x", item) }
    contents[:idm] = idm.join
    contents[:pmm] = pmm.join
    contents[:history] = @history
    return yaml.to_json
  end
  
  def get2byte(da,offset)
    return (da[offset] << 8) | da[offset+1]
  end
  
  def get4byte(da,offset)
    return (da[offset] << 24) |(da[offset+1] << 16) |(da[offset+2] << 8) | da[offset+3]
  end

  def get_console_type(ctype)
    case ctype
    when 0x03; "清算機"
    when 0x05; "車載端末"
    when 0x08; "券売機"
    when 0x12; "券売機"
    when 0x16; "改札機"
    when 0x17; "簡易改札機"
    when 0x18; "窓口端末"
    when 0x1a; "改札端末"
    when 0x1b; "携帯電話"
    when 0x1c; "乗継清算機"
    when 0x1d; "連絡改札機"
    when 0xc7; "物販"
    when 0xc8; "自販機"
    else "???"
    end
  end

  def get_proc_type(proc)
    case proc
    when 0x01; "運賃支払"
    when 0x02; "チャージ"
    when 0x03; "券購"
    when 0x04; "清算"
    when 0x07; "新規"
    when 0x0d; "バス"
    when 0x0f; "バス"
    when 0x14; "オートチャージ"
    when 0x46; "物販"
    when 0x49; "入金"
    when 0xc6; "物販(現金併用)"
    else "???"
    end
  end
  
  # 入出金情報取得
  def get_deposit_info(da,p)
    p[:time] = nil
    p[:in_line] = nil
    p[:in_sta] = nil
    p[:out_line] = nil
    p[:out_sta] = nil
    case p[:ctype]
    when 0xC7, 0x08 #  // 物販(0xC7), 自販機(0x08)
      p[:time] = get2byte(da,6)
      p[:in_line] = da[8]
      p[:in_sta] = da[9]
    when 0x05 # // 車載機(0x05)
      p[:in_line] = get2byte(da, 6)
      p[:in_sta] = get2byte(da, 8)
    else
      p[:in_line] = da[6];
      p[:in_sta] = da[7];
      p[:out_line] = da[8];
      p[:out_sta] = da[9];
    end
  end

  # 入出金履歴取得
  def pasori_history_read
    index = 0
    data = ' ' * 16
    while 0 == PasoriAPI::felica_read_without_encryption02(@base_ptr, SERVICE_SUICA_HISTORY, 0, index, data) do
      da = data.unpack('C*')
      p = Hash.new
      p[:ctype] = da[0]
      p[:proc] = da[1]
      p[:date] = get2byte(da,4)
      p[:balance] = PasoriAPI::n2hs(get2byte(da,10))
      seq = get4byte(da,12)
      p[:region] = seq & 0xff
      p[:seq] = seq >> 8
      
      get_deposit_info(da,p)
      
      p[:ctype_name] = get_console_type(p[:ctype])
      p[:proc_name] = get_proc_type(p[:proc])
      p[:date_string] = sprintf("%02d/%02d/%02d", (p[:date] >> 9), ((p[:date] >> 5) & 0xf), (p[:date] & 0x1f) )
      
      p[:time_string] = nil
      if !p[:time].nil?
        p[:time_string] = sprintf("%02d:%02d", (p[:time] >> 11), ((p[:time] >> 5) & 0x3f))
      end
      
      @history << p
      index += 1
    end
    puts @history
    return true
  end
  
  def pasori_dump_read
    # システムコード
    system_code_ptr = PasoriAPI::felica_enum_systemcode(@pasori_ptr);
    system_code = PasoriAPI::Felica.new(system_code_ptr)
    puts "num_system_code[#{system_code.num_system_code}]"
    puts "system_code[#{system_code.system_code}]"
    
    (0..(system_code.num_system_code-1)).each do |index|
      printf "system_code[%04X]\n", PasoriAPI::n2hs(system_code.system_code[index])
      enum_service_ptr = PasoriAPI::felica_enum_service(@pasori_ptr, PasoriAPI::n2hs(system_code.system_code[index]) )
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
  end

  def pasori_disconnect
    if ! @base_ptr.nil?
      PasoriAPI::felica_free(@base_ptr)
      @base_ptr = nil
    end
    if ! @pasori_ptr.nil?
      PasoriAPI::pasori_close(@pasori_ptr)
      @pasori_ptr = nil
    end
  end


  
end
