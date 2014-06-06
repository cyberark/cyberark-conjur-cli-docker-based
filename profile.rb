#!/usr/bin/env ruby
require 'ruby-prof'

result = RubyProf.profile do
  require 'conjur/cli'
  Conjur::CLI.run(ARGV)
end


`mkdir -p #{File.dirname(__FILE__)}/profile`
File.open("profile/graph.html", "w") do |io|
  grapher = RubyProf::GraphHtmlPrinter.new(result)
  grapher.print(io)
end
File.open("profile/stack.html", "w") do |io|
  printer = RubyProf::CallStackPrinter.new(result)
  printer.print(io)
end

