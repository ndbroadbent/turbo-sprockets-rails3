Dir[File.expand_path('../turbo-sprockets/sprockets_overrides/*.rb', __FILE__)].each do |f|
  require f
end

#require 'turbo-sprockets/railtie'
