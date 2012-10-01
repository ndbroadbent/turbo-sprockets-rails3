source "http://rubygems.org"

# Specify your gem's dependencies in sprockets-rails.gemspec
gemspec

gem 'rails', '3.2.8'

gem "uglifier", :require => false
gem "mocha", :require => false
gem "jquery-rails"

unless ENV['CI']
  gem "debugger", :platform => :mri_19
end
