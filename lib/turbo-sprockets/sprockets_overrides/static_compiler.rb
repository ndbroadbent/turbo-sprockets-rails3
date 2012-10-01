begin
  require 'sprockets/static_compiler'
rescue LoadError
end

# Sprockets::StaticCompiler was only introduced in Rails 3.2.x
if defined?(Sprockets::StaticCompiler)
  module Sprockets
    StaticCompiler.class_eval do
      def initialize(env, target, paths, options = {})
        @env = env
        @target = target
        @paths = paths
        @digest = options.fetch(:digest, true)
        @manifest = options.fetch(:manifest, true)
        @manifest_path = options.delete(:manifest_path) || target
        @zip_files = options.delete(:zip_files) || /\.(?:css|html|js|svg|txt|xml)$/

        @current_source_digests = options.fetch(:source_digests, {})
        @current_digest_files   = options.fetch(:digest_files,   {})

        @digest_files   = {}
        @source_digests = {}
      end

      def compile
        start_time = Time.now.to_f

        env.each_logical_path do |logical_path|
          if File.basename(logical_path)[/[^\.]+/, 0] == 'index'
            logical_path.sub!(/\/index\./, '.')
          end
          next unless compile_path?(logical_path)

          # Fetch asset without any processing or compression,
          # to calculate a digest of the concatenated source files
          asset = env.find_asset(logical_path, :process => false)

          # Force digest to UTF-8 for Ruby 1.9, otherwise YAML dumps ASCII-8BIT as !binary
          @source_digests[logical_path] = if RUBY_VERSION.to_f >= 1.9
            asset.digest.force_encoding("UTF-8")
          else
            asset.digest
          end

          # Recompile if digest has changed or compiled digest file is missing
          current_digest_file = @current_digest_files[logical_path]

          if @source_digests[logical_path] != @current_source_digests[logical_path] ||
             !(current_digest_file && File.exists?("#{@target}/#{current_digest_file}"))

            if asset = env.find_asset(logical_path)
              @digest_files[logical_path] = write_asset(asset)
            end

          else
            # Set asset file from manifest.yml
            digest_file = @current_digest_files[logical_path]
            @digest_files[logical_path] = digest_file

            env.logger.debug "Not compiling #{logical_path}, sources digest has not changed " <<
                             "(#{@source_digests[logical_path][0...7]})"
          end
        end

        if @manifest
          write_manifest(:source_digests => @source_digests, :digest_files => @digest_files)
        end

        # Store digests in Rails config. (Important if non-digest is run after primary)
        config = ::Rails.application.config
        config.assets.digest_files   = @digest_files
        config.assets.source_digests = @source_digests

        elapsed_time = ((Time.now.to_f - start_time) * 1000).to_i
        env.logger.debug "Processed #{'non-' unless @digest}digest assets in #{elapsed_time}ms"
      end
    end
  end
end