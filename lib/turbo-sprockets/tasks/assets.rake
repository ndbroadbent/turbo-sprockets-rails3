require "fileutils"

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
      config.assets.digest  = digest unless digest.nil?
      config.assets.digest_files   ||= {}
      config.assets.source_digests ||= {}

      env    = Rails.application.assets
      target = File.join(::Rails.public_path, config.assets.prefix)

      # If processing non-digest assets, and compiled digest files are
      # present, then generate non-digest assets from existing assets.
      # It is assumed that `assets:precompile:nondigest` won't be run manually
      # if assets have been previously compiled with digests.
      if !config.assets.digest && config.assets.digest_files.any?
        generator = Sprockets::StaticNonDigestGenerator.new(env, target, config.assets.precompile,
          :digest_files => config.assets.digest_files)
        generator.generate
      else
        compiler = Sprockets::StaticCompiler.new(env, target, config.assets.precompile,
          :digest         => config.assets.digest,
          :manifest       => digest.nil?,
          :manifest_path  => config.assets.manifest,
          :digest_files   => config.assets.digest_files,
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