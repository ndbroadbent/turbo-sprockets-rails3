Dir[File.expand_path('../turbo-sprockets/sprockets_overrides/**/*.rb', __FILE__)].each do |f|
  require f
end

require 'sprockets/railtie'
require 'sprockets/helpers'
require 'turbo-sprockets/railtie'
