require 'json'
require_relative '../lib/hash_remapper'

# https://samples.openweathermap.org/data/2.5/weather?q=London,uk&appid=b6907d289e10d714a6e88b30761fae22
weather = JSON.parse('{"coord":{"lon":-0.13,"lat":51.51},"weather":[{"id":300,"main":"Drizzle","description":"light intensity drizzle","icon":"09d"}],"base":"stations","main":{"temp":280.32,"pressure":1012,"humidity":81,"temp_min":279.15,"temp_max":281.15},"visibility":10000,"wind":{"speed":4.1,"deg":80},"clouds":{"all":90},"dt":1485789600,"sys":{"type":1,"id":5091,"message":0.0103,"country":"GB","sunrise":1485762037,"sunset":1485794875},"id":2643743,"name":"London","cod":200}')

k_to_c = ->(kelvin) { "#{(kelvin - 273.15).floor}˚C" } # notice the difference with the next example

remapped_weather = HashRemapper.remap(
  weather,
  # deep keys creation instead of automerge
  _conditions: [[:current_conditions, :description], {path: 'weather.0', lambda: ->(res){ "#{res[:description]}".capitalize }} ],
  _temperature: [[:current_conditions, :temperature], {path: 'main.temp', lambda: k_to_c}],

  _clouds: [[:clouds_coverage, :percentage], {path: 'clouds.all'}],
  'visibility' => ->(vis, _) { [:visibility, "#{vis / 1000}km"] },
  ['sys', 'country'] => ->(country, _) { [[:place, :country], country] },
  'name' => ->(city, _) { [[:place, :city], city] },
  'coord' => :geo_coordinates
)

p remapped_weather

# =================================================================================================================================

k_to_c = ->(kelvin) { { temperature: "#{(kelvin - 273.15).floor}˚C" } } # notice the difference with the previous example

remapped_weather = HashRemapper.remap(
  weather,
  # automerge on "conflict"
  _conditions: [:current_conditions, {path: 'weather.0', lambda: ->(res){ { description: "#{res[:description]}".capitalize }}} ],
  _temperature: [:current_conditions, {path: 'main.temp', lambda: k_to_c}], # automerge
  _clouds: [[:clouds_coverage, :percentage], {path: 'clouds.all'}],
  'visibility' => ->(vis, _) { [:visibility, "#{vis / 1000}km"] },
  ['sys', 'country'] => ->(country, _) { [[:place, :country], country] },
  'name' => ->(city, _) { [[:place, :city], city] },

  # notice the nested HashRemapper (alternatively https://devdocs.io/rails~5.0/hash#method-i-deep_symbolize_keys could be used on overall result)
  'coord' => ->(coord, _) { [:geo_coordinates, HashRemapper.remap(coord, 'lon' => :lon, 'lat' => :lat)] },
)

p remapped_weather
