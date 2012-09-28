require 'sprockets/bundled_asset'

module Sprockets
  BundledAsset.class_eval do

    # Adds :process options

    def initialize(environment, logical_path, pathname, options = {})
      super(environment, logical_path, pathname)
      @process = options.fetch(:process, true)

      @processed_asset  = environment.find_asset(pathname, :bundle => false, :process => @process)
      @required_assets  = @processed_asset.required_assets
      @dependency_paths = @processed_asset.dependency_paths

      @source = ""

      # Explode Asset into parts and gather the dependency bodies
      to_a.each { |dependency| @source << dependency.to_s }

      if @process
        # Run bundle processors on concatenated source
        context = environment.context_class.new(environment, logical_path, pathname)
        @source = context.evaluate(pathname, :data => @source,
                    :processors => environment.bundle_processors(content_type))
      end

      @mtime  = to_a.map(&:mtime).max
      @length = Rack::Utils.bytesize(source)
      @digest = environment.digest.update(source).hexdigest
    end
  end
end