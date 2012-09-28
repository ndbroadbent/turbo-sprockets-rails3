require 'sprockets/index'

module Sprockets
  Index.class_eval do

    # Adds :process options

    def find_asset(path, options = {})
      options[:bundle]  = true unless options.key?(:bundle)
      options[:process] = true unless options.key?(:process)

      if asset = @assets[cache_key_for(path, options)]
        asset
      elsif asset = super
        logical_path_cache_key = cache_key_for(path, options)
        full_path_cache_key    = cache_key_for(asset.pathname, options)

        # Cache on Index
        @assets[logical_path_cache_key] = @assets[full_path_cache_key] = asset

        # Push cache upstream to Environment
        @environment.instance_eval do
          @assets[logical_path_cache_key] = @assets[full_path_cache_key] = asset
        end

        asset
      end
    end
  end
end