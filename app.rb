require 'json'
require 'sinatra'
require 'yaml'

class DataParser

  def all_json
    @all_json ||= {
      zone_lookup: zone_lookup,
      courrier_delivery_prices: courrier_delivery_prices,
      pickup_point_delivery_prices: pickup_point_delivery_prices,
      city_delivery_types: city_delivery_types
    }.to_json
  end

  private

  def zone_lookup
    result = {}
    data = YAML.load_file File.expand_path('../data/zone_lookup.yml', __FILE__)
    regions = data.keys
    data.each do |key, value|
      result[key] = {}
      zones = value.split(' ').map{ |v| v == '~' ? nil : v }
      regions.each_with_index do |region, i|
        result[key][region] = zones[i]
      end
    end
    result
  end

  def courrier_delivery_prices
    parse_delivery_prices File.expand_path('../data/courrier_delivery_prices.yml', __FILE__)
  end

  def pickup_point_delivery_prices
    parse_delivery_prices File.expand_path('../data/pickup_point_delivery_prices.yml', __FILE__)
  end

  def city_delivery_types
    result = {}
    data = YAML.load_file File.expand_path('../data/city_delivery_types.yml', __FILE__)
    data['cities'].each do |key, value|
      result[key] = {}
      values = value.split(' ').map{ |v| v == '+' }
      data['types'].each_with_index do |type, i|
        result[key][type] = values[i]
      end
    end
    result
  end

  def parse_delivery_prices(filepath)
    result = {}
    data = YAML.load_file filepath
    data['zones'].each do |zone_name, zone_prices|
      zone_prices = zone_prices.split(' ').map &:to_f
      result[zone_name] = {}
      price_index = -1
      data['ranges'].each do |range_name|
        result[zone_name][range_name] = {
          base:     zone_prices[price_index += 1],
          extra_kg: zone_prices[price_index += 1]
        }
      end
    end
    result
  end

end

data = DataParser.new

get '/' do
  content_type :json, charset: 'utf-8'
  data.all_json
end
