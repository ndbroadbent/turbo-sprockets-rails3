#!/usr/bin/env rake
require 'rake/testtask'
ENV["TEST_CORES"] = "1"

require 'bundler'
Bundler::GemHelper.install_tasks

namespace :test do
  task :isolated do
    Dir["test/assets*_test.rb"].each do |file|
      dash_i = [
        'test',
        'lib',
      ]
      ruby "-I#{dash_i.join ':'}", file
    end
  end
end

Rake::TestTask.new("test:regular") do |t|
  t.libs << 'lib'
  t.libs << 'test'
  t.pattern = 'test/**/sprockets*_test.rb'
  t.verbose = true
end

task :test => ['test:isolated', 'test:regular']
task :default => :test
