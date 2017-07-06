#!/usr/bin/env rake
require "bundler/gem_tasks"

begin
  require 'ci/reporter/rake/rspec'
  require 'ci/reporter/rake/cucumber'
  require 'cucumber'
  require 'cucumber/rake/task'
  require 'rspec/core/rake_task'

  # spec reports get written to spec/reports by default
  RSpec::Core::RakeTask.new :spec do |t|
    t.rspec_opts = '--tag ~wip --format junit'
  end

  Cucumber::Rake::Task.new :features

  task :jenkins => ['ci:setup:rspec', :spec] do
    File.write('build_number', ENV['BUILD_NUMBER']) if ENV['BUILD_NUMBER']
    require 'fileutils'
    FileUtils.rm_rf 'features/reports'
    Cucumber::Rake::Task.new do |t|
      t.cucumber_opts = "--tags ~@real-api --format pretty --format junit --out features/reports"
    end.runner.run
  end

  task default: [:spec, :features]
rescue LoadError
  $stderr.puts $!
  $stderr.puts "This error will be ignored"
end
