#!/usr/bin/env rake
require "bundler/gem_tasks"
require 'ci/reporter/rake/rspec'
require 'ci/reporter/rake/cucumber'
require 'cucumber'
require 'cucumber/rake/task'
require 'rspec/core/rake_task'

RSpec::Core::RakeTask.new :spec
Cucumber::Rake::Task.new :features

task :jenkins => ['ci:setup:rspec', :spec, 'ci:setup:cucumber_report_cleanup'] do
  Cucumber::Rake::Task.new do |t|
    t.cucumber_opts = "--tags ~@real-api --format progress --format CI::Reporter::Cucumber --out features/reports"
  end.runner.run
  File.write('build_number', ENV['BUILD_NUMBER']) if ENV['BUILD_NUMBER']
end

task default: [:spec, :features]
