$:.push File.expand_path("../lib", __FILE__)

require "turbo-sprockets/version"

Gem::Specification.new do |s|
  s.name        = "turbo-sprockets-rails3"
  s.version     = TurboSprockets::VERSION
  s.authors     = ["Nathan Broadbent"]
  s.email       = ["nathan.f77@gmail.com"]
  s.homepage    = "https://github.com/ndbroadbent/turbo-sprockets-rails3"
  s.summary     = "Supercharge your Rails 3 asset pipeline"
  s.description = "Speeds up the Rails 3 asset pipeline by only recompiling changed assets"

  s.files = Dir["{app,config,db,lib}/**/*"] + ["MIT-LICENSE", "Rakefile", "README.rdoc"]
  s.test_files = Dir["test/**/*"]

  s.add_runtime_dependency "sprockets", "~> 2.1.3"
  s.add_runtime_dependency "railties",  "~> 3.2.0"
end
