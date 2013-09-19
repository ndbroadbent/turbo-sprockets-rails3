module Sprockets
  class UnprocessedAsset < AssetWithDependencies
    def initialize(environment, logical_path, pathname)
      super

      @environment = environment
      context = environment.context_class.new(environment, logical_path, pathname)
      attributes = environment.attributes_for(pathname)
      preprocessors = environment.preprocessors(content_type)

      # Remove all postprocessors and engines except ERB to return unprocessed source file
      allowed_engines = [Tilt::ERBTemplate]
      processors = preprocessors + (allowed_engines & attributes.engines)

      @source = context.evaluate(pathname, :processors => processors)

      # If the source contains any '@import' directives, add Sass and Less processors.
      # (@import is quite difficult to handle properly without processing.)
      if @source.include?("@import")
        # Process Sass and Less files, since @import is too tricky to handle properly.
        allowed_engines << Sass::Rails::ScssTemplate if defined?(Sass::Rails::ScssTemplate)
        allowed_engines << Sass::Rails::SassTemplate if defined?(Sass::Rails::SassTemplate)
        allowed_engines << Less::Rails::LessTemplate if defined?(Less::Rails::LessTemplate)
        processors = preprocessors + (allowed_engines & attributes.engines)
        @source = context.evaluate(pathname, :processors => processors)
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
