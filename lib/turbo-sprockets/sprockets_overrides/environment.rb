require 'sprockets/environment'

module Sprockets
  Environment.class_eval do

    # Adds :process options

    def find_asset(path, options = {})
      options[:bundle] = true unless options.key?(:bundle)
      options[:process] = true unless options.key?(:process)

      # Ensure in-memory cached assets are still fresh on every lookup
      if (asset = @assets[cache_key_for(path, options)]) && asset.fresh?(self)
        asset
      elsif asset = index.find_asset(path, options)
        # Cache is pushed upstream by Index#find_asset
        asset
      end
    end
  end
end