# This is the class that represents an instance type/OS/availability zone permutation.

uri = URI.parse(ENV['CUSTOM_MONGO_URL'])
MongoMapper.connection = Mongo::Connection.from_uri(ENV['CUSTOM_MONGO_URL'])
MongoMapper.database = uri.path.gsub(/^\//, '')

class InstanceType
  include MongoMapper::Document

  key :name, String
  key :availability_zone, String
  key :product_description, String
  key :pricing_history, Hash, :default => {}
  key :current_price, Float
  
end
