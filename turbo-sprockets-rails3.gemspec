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

  s.files = Dir["{app,config,db,lib}/**/*"] + ["MIT-LICENSE", "Rakefile", "README.md"]
  s.test_files = Dir["test/**/*"]

  s.add_runtime_dependency "sprockets", ">= 2.2.0"
  s.add_runtime_dependency "railties",  "> 3.2.8", '< 4.0.0'

  s.add_development_dependency "minitest", "~> 2.3.0"
  s.add_development_dependency "mocha", "~> 0.13.3"
end
