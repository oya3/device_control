# coding: utf-8
$LOAD_PATH.unshift(File.expand_path(File.dirname(__FILE__)))

require 'Qt4'
require 'qtuitools'
require 'yaml'
require 'json'

require 'pry'

class ServerWidget < Qt::Widget
  WIDGET_NAME = "device server"
  VERSION = "ver.0.2015.04.14.1700"
  
  attr_accessor :ic_card_device
  attr_accessor :parameter
  attr_accessor :ui
  
  def initialize(parent = nil)
    super(parent)
    
    # 画面構成読み込み＆設定
    @formWidget = nil
    Qt::File.new("qt_server.ui") do |file|
      loader = Qt::UiLoader.new
      file.open(Qt::File::ReadOnly)
      @formWidget = loader.load(file, self)
    end
    
    Qt::MetaObject.connectSlotsByName(self) # イベント接続
    
    # 画面構成に対応する設定情報読み込み＆設定
    @parameter = get_parameter('parameter.yml') # エラーハンドリング無視。。。
    @ui = set_parameter(@parameter)
    # 読み込んだ widget を追加(縦方向)
    layout = Qt::VBoxLayout.new
    layout.addWidget(@formWidget)
    setLayout(layout)
    setAcceptDrops(true) # drop 許可
    self.windowTitle = WIDGET_NAME + ' ' + VERSION
  end
  
  # パラメータ設定
  def set_parameter(parameter)
    ui = Hash.new
    ui['label_user_msg'] = findChild(Qt::Label, "label_user_msg")
    ui['listWidget_log'] = findChild(Qt::ListWidget, "listWidget_log")
    ui['lineEdit_ip'] = findChild(Qt::LineEdit, "lineEdit_ip")
    # set port number
    ui['lineEdit_ip'].text = parameter['contents']['ip'] + ':' + parameter['contents']['port']
    return ui
  end
  
  # パラメータ取得
  def get_parameter(filepath)
    buffer = nil #Hash.new
    File.open(filepath) do |file|
      buffer = file.read
    end
    if buffer.nil?
      return nil
    end
    return YAML.load(buffer)
  end
  
  def dragEnterEvent(event)
    if event.mimeData().hasFormat("text/uri-list")
      event.acceptProposedAction()
    else
      event.ignore()
    end
  end
  
  def dropEvent(event)
    if event.mimeData().hasFormat("text/uri-list")
      drop_file = event.mimeData().urls().first().toLocalFile() # windows: drop_file は utf-8 で入ってくる。 mac: ???
      puts drop_file.force_encoding('utf-8').encode('cp932')
      wlog('drop file:' + drop_file.force_encoding('utf-8'))
      
      File.open(drop_file.force_encoding('utf-8').encode('cp932')) do |file|
        yaml = YAML.load(file.read)
        ic_card_device.set_data yaml.to_json
      end
    else
      event.ignore()
    end
  end
  
  def wlog(message)
    @ui['listWidget_log'].addItem("#{Time.now}:#{message}")
  end
  
end

