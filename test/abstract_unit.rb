require 'rubygems'
require 'bundler/setup'

require 'turbo-sprockets-rails3'
require 'fileutils'

# Require minitest for 1.9 and test/unit for 1.8
# 'active_support/test_case' supports both.
begin
  require 'minitest/autorun'
rescue LoadError
  require 'test/unit'
end

require 'active_support/test_case'
require 'rails/generators'
require "active_support/testing/isolation"
require "active_support/core_ext/kernel/reporting"

module TestHelpers
  module Paths
    TMP_PATH = File.expand_path(File.join(File.dirname(__FILE__), *%w[.. tmp]))

    def tmp_path(*args)
      File.join(TMP_PATH, *args)
    end

    def app_path(*args)
      tmp_path(*%w[app] + args)
    end

    def rails_root
      app_path
    end
  end

  module Rack
    def app(env = "production")
      old_env = ENV["RAILS_ENV"]
      @app ||= begin
        ENV["RAILS_ENV"] = env
        require "#{app_path}/config/environment"
        Rails.application
      end
    ensure
      ENV["RAILS_ENV"] = old_env
    end

    def get(path)
      @app.call(::Rack::MockRequest.env_for(path))
    end
  end

  module Generation
    # Build an application by invoking the generator and going through the whole stack.
    def build_app(options = {})
      @prev_rails_env = ENV['RAILS_ENV']
      ENV['RAILS_ENV'] = 'development'

      FileUtils.rm_rf(app_path)
      FileUtils.cp_r(tmp_path('app_template'), app_path)

      # Delete the initializers unless requested
      unless options[:initializers]
        Dir["#{app_path}/config/initializers/*.rb"].each do |initializer|
          File.delete(initializer)
        end
      end

      unless options[:gemfile]
        File.delete"#{app_path}/Gemfile"
      end

      routes = File.read("#{app_path}/config/routes.rb")
      if routes =~ /(\n\s*end\s*)\Z/
        File.open("#{app_path}/config/routes.rb", 'w') do |f|
          f.puts $` + "\nget ':controller(/:action(/:id))(.:format)'\n" + $1
        end
      end

      add_to_config 'config.secret_token = "3b7cd727ee24e8444053437c36cc66c4"; config.session_store :cookie_store, :key => "_myapp_session"; config.active_support.deprecation = :log'
    end

    def teardown_app
      ENV['RAILS_ENV'] = @prev_rails_env if @prev_rails_env
    end

    def add_to_config(str)
      environment = File.read("#{app_path}/config/application.rb")
      if environment =~ /(\n\s*end\s*end\s*)\Z/
        File.open("#{app_path}/config/application.rb", 'w') do |f|
          f.puts $` + "\n#{str}\n" + $1
        end
      end
    end

    def add_to_env_config(env, str)
      environment = File.read("#{app_path}/config/environments/#{env}.rb")
      if environment =~ /(\n\s*end\s*)\Z/
        File.open("#{app_path}/config/environments/#{env}.rb", 'w') do |f|
          f.puts $` + "\n#{str}\n" + $1
        end
      end
    end

    def app_file(path, contents)
      FileUtils.mkdir_p File.dirname("#{app_path}/#{path}")
      File.open("#{app_path}/#{path}", 'w') do |f|
        f.puts contents
      end
    end

    def boot_rails
      require 'rubygems' unless defined? Gem
      require 'bundler'
      Bundler.setup
    end
  end
end

class ActiveSupport::TestCase
  include TestHelpers::Paths
  include TestHelpers::Rack
  include TestHelpers::Generation
end

# Create a scope and build a fixture rails app
Module.new do
  extend TestHelpers::Paths
  # Build a rails app
  if File.exist?(tmp_path)
    FileUtils.rm_rf(tmp_path)
  end
  FileUtils.mkdir(tmp_path)

  quietly do
    Rails::Generators.invoke('app', ["#{tmp_path('app_template')}", "--skip-active-record", "--skip-test-unit"])
  end

  File.open("#{tmp_path}/app_template/config/boot.rb", 'w') do |f|
    f.puts 'require "action_controller/railtie"'
  end
end
