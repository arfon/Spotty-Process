require 'mongo_mapper'
require 'sinatra'
require 'memcachier'
require 'dalli'
require './bin/instance_type.rb'

configure :production do
  require 'newrelic_rpm'
end

# may need to configure client connection settings if not on Heroku (and not using something like https://addons.heroku.com/memcachier)
set :cache, Dalli::Client.new

# wrap the response in a callback if given
before do
  @callback = params.delete('callback')
end

get '/' do
  erb :index
end

get '/instances/:name/:availability_zone' do
  @instance = settings.cache.fetch("#{params[:name]}:#{params[:availability_zone]}:instance") do
    instance = InstanceType.find_all_by_name_and_availability_zone(params[:name], params[:availability_zone])
    # set unique key and cache for 120 seconds
    settings.cache.set("#{params[:name]}:#{params[:availability_zone]}:instance", instance, 120)
    instance
  end
  
  if @callback
    content_type :js
    response = "#{@callback}(#{@instance.to_json})" 
  else
    content_type :json
    response = @instance.to_json
  end
  
  response
end

get '/cheapest/:name' do  
  cheapest_linux = InstanceType.linux.sort(:current_price).find_all_by_name(params[:name]).first
  cheapest_windows = InstanceType.windows.sort(:current_price).find_all_by_name(params[:name]).first
  
  response = { :linux => cheapest_linux, :windows => cheapest_windows }
  
  if @callback
    content_type :js
    response = "#{@callback}(#{response.to_json})" 
  else
    content_type :json
    response = response.to_json
  end
end

get '/instances/:name' do  
  @instance = settings.cache.fetch("#{params[:name]}:instance") do
    instance = InstanceType.find_all_by_name(params[:name])
    settings.cache.set("#{params[:name]}:instance", instance, 120)
    instance
  end
  
  if @callback
    content_type :js
    response = "#{@callback}(#{@instance.to_json})" 
  else
    content_type :json
    response = @instance.to_json
  end
  
  response
end

get '/availability_zones/:zone' do  
  @instance = settings.cache.fetch("#{params[:zone]}:zone") do
    instance = InstanceType.find_all_by_availability_zone(params[:zone])
    settings.cache.set("#{params[:zone]}:zone", instance, 120)
    instance
  end
  
  if @callback
    content_type :js
    response = "#{@callback}(#{@instance.to_json})" 
  else
    content_type :json
    response = @instance.to_json
  end
  
  response
end
