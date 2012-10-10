module Sprockets
  class UnprocessedAsset < AssetWithDependencies
    def replace_imports(template_with_leading_underscore = true)
      @source.gsub!(/^@import ["']([^"']+)["'];?/) do |match|
        begin
          if template_with_leading_underscore
            template = "_#{$1}"
          else
            template = $1
          end
          pathname = @environment.resolve(template)
          asset = UnprocessedAsset.new @environment, template, pathname
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

      # Include SASS imports
      if defined?(Sass::Rails::ScssTemplate) && attributes.processors.include?(Sass::Rails::ScssTemplate)
        replace_imports(true)  # Template has leading underscore
      end
      # Include Less imports
      if defined?(Less::Rails::LessTemplate) && attributes.processors.include?(Less::Rails::LessTemplate)
        replace_imports(false)  # Template has no leading underscore
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
