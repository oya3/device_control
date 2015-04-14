# coding: utf-8
$LOAD_PATH.unshift(File.expand_path(File.dirname(__FILE__)))

require 'Qt4'
require 'qtuitools'
require 'yaml'

require 'pry'

class ServerWidget < Qt::Widget
  WIDGET_NAME = "device server."
  VERSION = "ver.0.2015.04.14.1700"
  
  attr_accessor :device
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
    setAcceptDrops(true)    
    self.windowTitle = WIDGET_NAME + VERSION
  end
  
  # パラメータ設定
  def set_parameter(parameter)
    ui = Hash.new
    ui['label_msg'] = findChild(Qt::Label, "label_msg")
    ui['listWidget_log'] = findChild(Qt::ListWidget, "listWidget_log")
    ui['lcdNumber_port'] = findChild(Qt::LCDNumber, "lcdNumber_port")
    # set port number
    ui['lcdNumber_port'].value = parameter['contents']['port']
    return ui
  end
  
  # パラメータ取得
  def get_parameter(filepath)
    buffer = nil #Hash.new
    File.open(filepath) do |file|
      buffer = file.read
    end
    if( buffer ) then
      return YAML.load(buffer)
    end
    return nil
  end

  def event(event)
    if event.type == Qt::Event::FileOpen
      puts "dropfile!!"
    end
    super(event)
  end
  
end

