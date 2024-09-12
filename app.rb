require 'sinatra'
require 'sinatra/json'
require 'httparty'
require 'json'

set :bind, '0.0.0.0'  # 添加這行，使 Sinatra 監聽所有網絡介面

# OvenMediaEngine API 設定
OME_API_URL = "http://#{ENV['OME_HOST']}:8081/v1"

# 首頁
get '/' do
  erb :index
end

# 獲取所有串流
get '/api/streams' do
  response = HTTParty.get("#{OME_API_URL}/vhosts/default/apps/app/streams")
  json response.parsed_response
end

# 獲取特定串流資訊
get '/api/streams/:stream_name' do
  stream_name = params['stream_name']
  response = HTTParty.get("#{OME_API_URL}/vhosts/default/apps/app/streams/#{stream_name}")
  json response.parsed_response
end

# 啟動串流
post '/api/streams/:stream_name/start' do
  stream_name = params['stream_name']
  response = HTTParty.post("#{OME_API_URL}/vhosts/default/apps/app/streams/#{stream_name}/start")
  json response.parsed_response
end

# 停止串流
post '/api/streams/:stream_name/stop' do
  stream_name = params['stream_name']
  response = HTTParty.post("#{OME_API_URL}/vhosts/default/apps/app/streams/#{stream_name}/stop")
  json response.parsed_response
end