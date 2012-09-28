require 'sprockets/helpers/rails_helper'

module Sprockets
  module Helpers
    RailsHelper.module_eval do
      def asset_paths
        @asset_paths ||= begin
          paths = RailsHelper::AssetPaths.new(config, controller)
          paths.asset_environment = asset_environment
          paths.digest_files      = digest_files
          paths.compile_assets    = compile_assets?
          paths.digest_assets     = digest_assets?
          paths
        end
      end

      private
      def digest_files
        Rails.application.config.assets.digest_files
      end
    end

    RailsHelper::AssetPaths.class_eval do
      attr_accessor :digest_files

      def digest_for(logical_path)
        if digest_assets && digest_files && (digest = digest_files[logical_path])
          return digest
        end

        if compile_assets
          if digest_assets && asset = asset_environment[logical_path]
            return asset.digest_path
          end
          return logical_path
        else
          raise AssetNotPrecompiledError.new("#{logical_path} isn't precompiled")
        end
      end
    end
  end
end