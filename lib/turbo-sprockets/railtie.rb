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

      if config.assets.manifest
        manifest_path = File.join(config.assets.manifest, "manifest.yml")
      else
        manifest_path = File.join(Rails.public_path, config.assets.prefix, "manifest.yml")
      end

      if File.exist?(manifest_path)
        manifest = YAML.load_file(manifest_path)
        config.assets.digest_files   = manifest[:digest_files]   || {}
        config.assets.source_digests = manifest[:source_digests] || {}
      end
    end
  end
end