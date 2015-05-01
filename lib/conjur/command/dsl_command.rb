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

class Conjur::DSLCommand < Conjur::Command
  class << self
    def run_script(args, options, &block)
      Conjur.log = "stderr"

      filename = nil
      script = if script = args.pop
        filename = script
        script = if File.exists?(script)
          File.read(script)
        else
          require 'open-uri'
          uri = URI.parse(script)
          raise "Unable to read this kind of URL : #{script}" unless uri.respond_to?(:read)
          begin
            uri.read
          rescue OpenURI::HTTPError
            raise "Unable to read URI #{script} : #{$!.message}"
          end
        end
      else
        STDIN.read
      end
      
      require 'conjur/dsl/runner'
      runner = Conjur::DSL::Runner.new(script, filename)
      runner.owner = options[:ownerid] if options[:ownerid]

      if context = options[:context]
        runner.context = begin
          JSON.parse(File.read(context)) 
        rescue Errno::ENOENT 
          {}
        end
      end
      
      if block_given?
        block.call(runner) do
          runner.execute
        end
      else
        runner.execute
      end
      
      if context
        File.write(context, JSON.pretty_generate(runner.context))
        File.chmod(0600, context)
      end

      puts JSON.pretty_generate(runner.context)
    end
  end

end