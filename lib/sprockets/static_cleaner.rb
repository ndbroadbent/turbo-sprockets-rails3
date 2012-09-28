require 'fileutils'

module Sprockets
  class StaticCleaner
    attr_accessor :env, :target

    def initialize(env, target, digest_files)
      @env = env
      @target = File.join(target, '') # Make sure target ends with trailing /
      @digest_files = digest_files
    end

    # Remove all files from `config.assets.prefix` that are not found in manifest.yml
    def remove_old_assets!
      known_files = @digest_files.flatten
      known_files += known_files.map {|f| "#{f}.gz" } # Recognize gzipped files
      known_files << 'manifest.yml'

      assets_prefix = ::Rails.application.config.assets.prefix

      Dir[File.join(target, "**/*")].each do |path|
        unless File.directory?(path)
          logical_path = path.sub(target, '')
          unless logical_path.in? known_files
            FileUtils.rm path
            env.logger.debug "Deleted old asset at public#{assets_prefix}/#{logical_path}"
          end
        end
      end

      # Remove empty directories (reversed to delete top-level empty dirs first)
      Dir[File.join(target, "**/*")].reverse.each do |path|
        if File.exists?(path) && File.directory?(path) && (Dir.entries(path) - %w(. ..)).empty?
          FileUtils.rmdir path
          logical_path = path.sub(target, '')
          env.logger.debug "Deleted empty directory at public#{assets_prefix}/#{logical_path}"
        end
      end
    end
  end
end