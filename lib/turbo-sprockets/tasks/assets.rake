require "fileutils"
require 'shellwords'

# Clear all assets tasks from sprockets railtie,
# but preserve any extra actions added via 'enhance'
task_enhancements = {}
Rake::Task.tasks.each do |task|
  if task.name.match '^assets:'
    task_enhancements[task.name] = task.actions[1..-1] if task.actions.size > 1
    task.clear
  end
end

# Replace with our extended assets tasks
namespace :assets do
  def ruby_rake_task(task, fork = true)
    env    = ENV['RAILS_ENV'] || 'production'
    groups = ENV['RAILS_GROUPS'] || 'assets'
    args   = [$0, task,"RAILS_ENV=#{env}","RAILS_GROUPS=#{groups}"]
    args << "--trace" if Rake.application.options.trace
    if $0 =~ /rake\.bat\Z/i
      Kernel.exec $0, *args
    else
      fork ? ruby(*args) : Kernel.exec(FileUtils::RUBY, *args)
    end
  end

  # We are currently running with no explicit bundler group
  # and/or no explicit environment - we have to reinvoke rake to
  # execute this task.
  def invoke_or_reboot_rake_task(task)
    if ENV['RAILS_GROUPS'].to_s.empty? || ENV['RAILS_ENV'].to_s.empty?
      ruby_rake_task task
    else
      Rake::Task[task].invoke
    end
  end

  # Returns an array of assets recognized by config.assets.digests,
  # including gzipped assets and manifests
  def known_assets
    assets = Rails.application.config.assets.digests.to_a.flatten.map do |asset|
      [asset, "#{asset}.gz"]
    end.flatten
    assets + %w(manifest.yml sources_manifest.yml)
  end

  desc "Compile all the assets named in config.assets.precompile"
  task :precompile do
    invoke_or_reboot_rake_task "assets:precompile:all"
  end

  namespace :precompile do
    def internal_precompile(digest=nil)
      unless Rails.application.config.assets.enabled
        warn "Cannot precompile assets if sprockets is disabled. Please set config.assets.enabled to true"
        exit
      end

      # Ensure that action view is loaded and the appropriate
      # sprockets hooks get executed
      _ = ActionView::Base

      config = Rails.application.config
      config.assets.compile = true
      config.assets.clean_after_precompile = false if config.assets.clean_after_precompile.nil?
      config.assets.digest = digest unless digest.nil?
      config.assets.digests        ||= {}
      config.assets.source_digests ||= {}
      config.assets.handle_expiration = false if config.assets.handle_expiration.nil?

      env    = Rails.application.assets
      target = File.join(::Rails.public_path, config.assets.prefix)

      # This takes a long time to run if you aren't cleaning expired assets.
      # You must call the assets:clean_expired rake task regularly if this is
      # enabled
      if config.assets.handle_expiration
        # Before first compile, set the mtime of all current assets to current time.
        # This time reflects the last time the assets were being used.
        if digest.nil?
          ::Rails.logger.debug "Updating mtimes for current assets..."
          paths = known_assets.map { |asset| File.join(target, asset) }
          paths.each_slice(100) do |slice|
            # File.utime raises 'Operation not permitted' unless user is owner of file.
            # Non-owners have permission to update mtime to the current time using 'touch'.
            `touch -c #{slice.shelljoin}`
          end
        end
      end

      # If processing non-digest assets, and compiled digest files are
      # present, then generate non-digest assets from existing assets.
      # It is assumed that `assets:precompile:nondigest` won't be run manually
      # if assets have been previously compiled with digests.
      if !config.assets.digest && config.assets.digests.any?
        generator = Sprockets::StaticNonDigestGenerator.new(env, target, config.assets.precompile,
          :digests => config.assets.digests)
        generator.generate
      else
        compiler = Sprockets::StaticCompiler.new(env, target, config.assets.precompile,
          :digest         => config.assets.digest,
          :manifest       => digest.nil?,
          :manifest_path  => config.assets.manifest,
          :digests        => config.assets.digests,
          :source_digests => config.assets.source_digests
        )
        compiler.compile
      end
    end

    task :all => ["assets:cache:clean"] do
      # Other gems may want to add hooks to run after the 'assets:precompile:***' tasks.
      # Since we aren't running separate rake tasks anymore, we manually invoke the extra actions.
      internal_precompile
      Rake::Task["assets:precompile:primary"].actions[1..-1].each &:call

      if ::Rails.application.config.assets.digest
        internal_precompile(false)
        Rake::Task["assets:precompile:nondigest"].actions[1..-1].each &:call
      end
    end

    task :primary => ["assets:cache:clean"] do
      internal_precompile
    end

    task :nondigest => ["assets:cache:clean"] do
      internal_precompile(false)
    end
  end

  desc "Remove old assets that aren't referenced by manifest.yml"
  task :clean_expired do
    invoke_or_reboot_rake_task "assets:clean_expired:all"
  end

  # Remove assets that haven't been deployed since `config.assets.expire_after` (default 1 day).
  # This provides a buffer between deploys, so that older assets can still be requested.
  # The precompile task updates the mtime of the current assets before compiling,
  # which indicates when they were last in use.
  #
  # The current assets are ignored, which is faster than the alternative of
  # setting their mtimes only to check them again.
  namespace :clean_expired do
    task :all => ["assets:environment"] do
      config = ::Rails.application.config
      expire_after = config.assets.expire_after || 1.day
      public_asset_path = File.join(::Rails.public_path, config.assets.prefix)

      @known_assets = known_assets

      Dir.glob(File.join(public_asset_path, '**/*')).each do |asset|
        next if File.directory?(asset)
        logical_path = asset.sub("#{public_asset_path}/", '')

        unless logical_path.in?(@known_assets)
          # Delete asset if not used for more than expire_after seconds
          if File.mtime(asset) < (Time.now - expire_after)
            ::Rails.logger.debug "Removing expired asset: #{logical_path}"
            FileUtils.rm_f asset
          end
        end
      end
    end
  end

  desc "Remove compiled assets"
  task :clean do
    invoke_or_reboot_rake_task "assets:clean:all"
  end

  namespace :clean do
    task :all => ["assets:cache:clean"] do
      config = ::Rails.application.config
      public_asset_path = File.join(::Rails.public_path, config.assets.prefix)
      rm_rf public_asset_path, :secure => true
    end
  end

  namespace :cache do
    task :clean => ["assets:environment"] do
      FileUtils.mkdir_p(File.join(::Rails.root.to_s, *%w(tmp cache assets)))
      ::Rails.application.assets.cache.clear
    end
  end

  task :environment do
    if ::Rails.application.config.assets.initialize_on_precompile
      Rake::Task["environment"].invoke
    else
      ::Rails.application.initialize!(:assets)
      Sprockets::Bootstrap.new(Rails.application).run
    end
  end
end


# Append previous task enhancements to new Rake tasks.
task_enhancements.each do |task_name, actions|
  actions.each do |proc|
    Rake::Task[task_name].enhance &proc
  end
end
