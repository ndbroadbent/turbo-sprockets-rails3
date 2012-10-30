source "http://rubygems.org"

# Specify your gem's dependencies in sprockets-rails.gemspec
gemspec

gem 'rails', '3.2.9.rc1'
gem "jquery-rails"

gem "uglifier", :require => false
gem "mocha", :require => false

unless ENV['CI']
  gem "debugger", :platform => :mri_19
end
