require 'sprockets/railtie'
require 'sprockets/helpers'

module Sprockets
  # Assets
  autoload :UnprocessedAsset,      "sprockets/unprocessed_asset"
  autoload :AssetWithDependencies, "sprockets/asset_with_dependencies"
end

Dir[File.expand_path('../turbo-sprockets/sprockets_overrides/**/*.rb', __FILE__)].each do |f|
  require f
end

require 'turbo-sprockets/railtie'
