#
# Copyright (C) 2014 Conjur Inc
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
require 'conjur/command'

class Conjur::DSLCommand < Conjur::Command
  class << self
    def file_or_stdin_arg(args)
    end

    def run_script(args, options, &block)
      filename = nil
      script = if script = args.pop
        filename = script
        script = File.read(script)
      else
        STDIN.read
      end
      
      require 'conjur/dsl/runner'
      runner = Conjur::DSL::Runner.new(script, filename)

      if context = options[:context]
        runner.context = begin
          JSON.parse(File.read(context)) 
        rescue Errno::ENOENT 
          {}
        end
      end
      
      result = nil
      if block_given?
        block.call(runner) do
          result = runner.execute
        end
      else
        result = runner.execute
      end
      
      if context
        File.write(context, JSON.pretty_generate(runner.context))
        File.chmod(0600, context)
      end

      puts JSON.pretty_generate(result)
    end
  end

end