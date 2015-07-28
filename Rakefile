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

desc "Generate the update completions file"
task :completions do
  # having 'lib' in the load path, which happens to be the case when running rake,
  # messes up GLIs commands_from
  $:.delete('lib')
  require 'conjur/cli'
  require 'yaml'

  Conjur::CLI.init!
  def ignore? name
    name = name.to_s
    # Ignore GLIs internal commands and one of our deprecated ones
    name.start_with?('_') or name.include?(':')
  end

  def visit cmd
    child = {}
    cmd.commands.each do |name, ccmd|
      next if ignore?(name)
      child[name] = visit(ccmd)
      child[name] = true if child[name].empty?
    end
    child
  end

  commands = visit Conjur::CLI

  File.open("#{File.dirname(__FILE__)}/bin/_conjur_completions.yaml", "w") do |io|
    YAML.dump(commands, io)
  end
end

task default: [:completions, :spec, :features]
