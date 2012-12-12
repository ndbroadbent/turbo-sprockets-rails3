source "http://rubygems.org"

# Specify your gem's dependencies in sprockets-rails.gemspec
gemspec

gem 'rails', '3.2.9'
gem "jquery-rails"

gem "uglifier", :require => false
gem "mocha", '0.12.7', :require => false

unless ENV['CI']
  gem "debugger", :platform => :mri_19
end
