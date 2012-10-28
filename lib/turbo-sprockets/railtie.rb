require "action_controller/railtie"

module Sprockets
  autoload :StaticNonDigestGenerator, "sprockets/static_non_digest_generator"
end

module TurboSprockets
  class Railtie < ::Rails::Railtie
    rake_tasks do
      load "turbo-sprockets/tasks/assets.rake"
    end

    initializer "turbo-sprockets.environment", :after => "sprockets.environment", :group => :all do |app|
      config = app.config

      manifest_dir = config.assets.manifest || File.join(Rails.public_path, config.assets.prefix)
      digests_manifest = File.join(manifest_dir, "manifest.yml")
      sources_manifest = File.join(manifest_dir, "sources_manifest.yml")
      config.assets.digests        = (File.exist?(digests_manifest) && YAML.load_file(digests_manifest)) || {}
      config.assets.source_digests = (File.exist?(sources_manifest) && YAML.load_file(sources_manifest)) || {}

      # Clear digests if loading previous manifest format
      config.assets.digests = {} if config.assets.digests[:digest_files]
    end
  end
end
