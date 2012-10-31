require 'sprockets/base'

module Sprockets
  Base.class_eval do
    protected

    def build_asset(logical_path, pathname, options)
      pathname = Pathname.new(pathname)

      # If there are any processors to run on the pathname, use
      # `BundledAsset`. Otherwise use `StaticAsset` and treat is as binary.
      if attributes_for(pathname).processors.any?
        if options[:bundle] == false
          circular_call_protection(pathname.to_s) do
            if options[:process] == false
              UnprocessedAsset.new(index, logical_path, pathname)
            else
              ProcessedAsset.new(index, logical_path, pathname)
            end
          end
        else
          BundledAsset.new(index, logical_path, pathname, options)
        end
      else
        StaticAsset.new(index, logical_path, pathname)
      end
    end

    private

    def cache_key_for(path, options)
      options[:process] = true unless options.key?(:process)
      key = "#{path}:#{options[:bundle] ? '1' : '0'}"
      key << ":0" unless options[:process]
      key
    end
  end
end