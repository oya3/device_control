# coding: utf-8

require 'open-uri'
require 'nokogiri'
require 'yaml'
require 'pry'

@station_codes = Array.new

def get_doc(url)
  charset = nil
  html = open(url) do |f|
    charset = f.charset # 文字種別を取得
    f.read # htmlを読み込んで変数htmlに渡す
  end
  # htmlをパース(解析)してオブジェクトを作成
  doc = Nokogiri::HTML.parse(html, nil, charset)
end

def get_station_data(tables)
  # 地区コード(16進)=0,線区コード(16進)=1,駅順コード(16進)=2,会社名=3,線区名=4,駅名=5,備考=6
  (2..(tables.length-1)).each do |y|
    table = tables[y]
    values = Hash.new
    begin
      values[:area_code] = sprintf("%03d", table.children[0].text.to_i(16))
      values[:station_code] = sprintf("%03d-%03d", table.children[1].text.to_i(16), table.children[2].text.to_i(16))
      values[:company] = table.children[3].text.encode('utf-8')
      values[:line_name] = table.children[4].text.encode('utf-8')
      values[:station_name] = table.children[5].text.encode('utf-8')
      values[:note] = table.children[6].text.encode('utf-8')
    rescue
      # 文字コード 不良がある
      next
    end
    @station_codes << values
  end
end

def out_station_code(file,base_url)
  yaml = Hash.new
  yaml[:content_type] = 'station_code'
  yaml[:content_version] = '0.1'
  yaml[:contents] = Hash.new
  contents = yaml[:contents]
  contents[:site] = "\"#{base_url}\""
  contents[:description] = "取得日：#{Time.now}"
  contents[:data] = Hash.new
  data = contents[:data]
  @station_codes.each do |values|
    key = values[:area_code] + '-' + values[:station_code]
    data[key] = Hash.new
    data[key][:line_name] = values[:line_name]
    data[key][:station_name] = values[:station_name]
    data[key][:note] = values[:note]
  end
  
  File.write( file, yaml.to_yaml)
end

base_url = 'http://www.denno.net/SFCardFan/index.php'
doc = get_doc(base_url)
# 件数取得
page_max = doc.xpath('//a[@title="last page"]').children.text.sub(/\[(\d+)\]/) {|word| $1}
puts "page_max:" + page_max
# page_max = 1 # for debug.
(1..(page_max.to_i)).each do |no|
  url = base_url + '?pageID=' + no.to_s
  puts url
  doc = get_doc(url)
  data = doc.xpath("//form[@id=\"add1\"]/center/table/tr")
  get_station_data(data)
end

out_station_code("station_code.yml", base_url)

puts 'complete.'
