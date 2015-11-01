require 'json'
require 'sinatra'
require 'yaml'

class DataParser

  def zone_lookup
    return @zone_lookup if @zone_lookup
    @zone_lookup = {}
    data = YAML.load_file File.expand_path('../data/zone_lookup.yml', __FILE__)
    regions = data.keys
    data.each do |key, value|
      @zone_lookup[key] = {}
      zones = value.split(' ').map{ |v| v == '~' ? nil : v }
      regions.each_with_index do |region, i|
        @zone_lookup[key][region] = zones[i]
      end
    end
    @zone_lookup = @zone_lookup.to_json
  end

  def courrier_delivery_prices
    @courrier_delivery_prices ||= parse_delivery_prices(File.expand_path('../data/courrier_delivery_prices.yml', __FILE__)).to_json
  end

  def pickup_point_delivery_prices
    @pickup_point_delivery_prices ||= parse_delivery_prices(File.expand_path('../data/pickup_point_delivery_prices.yml', __FILE__)).to_json
  end

  def city_delivery_types
    return @city_delivery_types if @city_delivery_types
    @city_delivery_types = {}
    data = YAML.load_file File.expand_path('../data/city_delivery_types.yml', __FILE__)
    data['cities'].each do |key, value|
      @city_delivery_types[key] = {}
      values = value.split(' ').map{ |v| v == '+' }
      data['types'].each_with_index do |type, i|
        @city_delivery_types[key][type] = values[i]
      end
    end
    @city_delivery_types = @city_delivery_types.to_json
  end

  private

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

before do
  content_type :json, charset: 'utf-8'
end

get '/' do
  content_type :html
  '<html>
    <body>
      <ul>
        <li><a href="/zone_lookup.json">zone_lookup.json</a>
        <li><a href="/courrier_delivery_prices.json">courrier_delivery_prices.json</a>
        <li><a href="/pickup_point_delivery_prices.json">pickup_point_delivery_prices.json</a>
        <li><a href="/city_delivery_types.json">city_delivery_types.json</a>
      </ul>
    </body>
  </html>'
end

get '/zone_lookup.json' do
  data.zone_lookup 
end

get '/courrier_delivery_prices.json' do
  data.courrier_delivery_prices
end

get '/pickup_point_delivery_prices.json' do
  data.pickup_point_delivery_prices
end

get '/city_delivery_types.json' do
  data.city_delivery_types
end
