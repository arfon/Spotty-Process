# run this script every ~10 minutes to update current prices.

require 'aws-sdk'
require 'mongo_mapper'
require 'rest-client'
require 'active_support'
require 'active_support/all'
require './instance_type.rb'

AWS.config({
  :access_key_id => ENV['AMAZON_ACCESS_KEY_ID'],
  :secret_access_key => ENV['AMAZON_SECRET_ACCESS_KEY']
})

ec2 = AWS::EC2.new
ec2.client

puts "Starting EC2 Spot API request"

end_time = Time.now.utc.iso8601
start_time = (Time.now - 12.hours).utc.iso8601

incoming = ec2.client.describe_spot_price_history(:start_time => start_time, :end_time => end_time)

pricing_count = 0

incoming[:spot_price_history_set].each do |pricing|
  pricing_count += 1
  instance = InstanceType.first_or_create(:name => pricing[:instance_type], 
                                          :availability_zone => pricing[:availability_zone], 
                                          :product_description => pricing[:product_description])

  instance.pricing_history["#{pricing[:timestamp]}"] = pricing[:spot_price]
  histories = instance.pricing_history.sort
  instance.pricing_history = {}
  histories.each { |h| instance.pricing_history[h[0]] = h[1] }
  instance.current_price = instance.pricing_history.values.last.to_f
  instance.save
end


