module Sprockets
  class UnprocessedAsset < AssetWithDependencies
    def replace_scss_imports
      @source.gsub!(/^@import ["']([^"']+)["']/) do |match|
        begin
          template = "_#{$1}"
          pathname = @environment.resolve(template)
          asset = UnprocessedAsset.new @environment, '_changeme2', pathname
          # Replace imported template with the unprocessed asset contents.
          asset.to_s
        rescue Sprockets::FileNotFound
          match
        end
      end
    end

    def initialize(environment, logical_path, pathname)
      super

      @environment = environment
      context = environment.context_class.new(environment, logical_path, pathname)
      attributes = environment.attributes_for(pathname)
      processors = attributes.processors

      # Remove all engine processors except ERB to return unprocessed source file
      processors -= (attributes.engines - [Tilt::ERBTemplate])

      @source = context.evaluate(pathname, :processors => processors)

      # Manually include files that are @imported from SCSS
      if defined?(Sass::Rails::ScssTemplate) && attributes.processors.include?(Sass::Rails::ScssTemplate)
        replace_scss_imports
      end

      build_required_assets(environment, context,  :process => false)
      build_dependency_paths(environment, context, :process => false)

      @dependency_digest = compute_dependency_digest(environment)
    end
  end

  # Return unprocessed dependencies when initializing asset from serialized hash
  def init_with(environment, coder)
    super(environment, coder, :process => false)
  end
end
