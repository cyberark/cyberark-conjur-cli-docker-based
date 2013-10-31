#
# Copyright (C) 2013 Conjur Inc
#
# Permission is hereby granted, free of charge, to any person obtaining a copy of
# this software and associated documentation files (the "Software"), to deal in
# the Software without restriction, including without limitation the rights to
# use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of
# the Software, and to permit persons to whom the Software is furnished to do so,
# subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS
# FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR
# COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER
# IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
# CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
#
require 'conjur/authn'
require 'conjur/command'

class Conjur::Command::Authn < Conjur::Command
  self.prefix = :script

  desc "Run a Conjur DSL script"
  arg_name "script"
  command :execute do |c|
    acting_as_option(c)
    
    c.desc "Load context from this config file; save it when finished"
    c.arg_name "context"
    c.flag [:c, :context]
    
    c.action do |global_options,options,args|
      filename = nil
      if script = args.pop
        filename = script
        script = File.read(script)
      else
        script = STDIN.read
      end
      require 'conjur/dsl/runner'
      runner = Conjur::DSL::Runner.new(script, filename)
      if options[:context]
        runner.context = begin
          JSON.parse(File.read(options[:context])) 
        rescue Errno::ENOENT 
          {}
        end
      end
      
      result = runner.execute
      
      if options[:context]
        File.write(options[:context], JSON.pretty_generate(runner.context))
      end

      puts JSON.pretty_generate(result)
    end
  end
end