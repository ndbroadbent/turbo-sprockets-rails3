require 'sprockets/asset'

module Sprockets
  Asset.class_eval do
    # Internal initializer to load `Asset` from serialized `Hash`.
    def self.from_hash(environment, hash)
      return unless hash.is_a?(Hash)

      klass = case hash['class']
        when 'BundledAsset'
          BundledAsset
        when 'ProcessedAsset'
          ProcessedAsset
        when 'UnprocessedAsset'
          UnprocessedAsset
        when 'StaticAsset'
          StaticAsset
        else
          nil
        end

      if klass
        asset = klass.allocate
        asset.init_with(environment, hash)
        asset
      end
    rescue UnserializeError
      nil
    end
  end
end