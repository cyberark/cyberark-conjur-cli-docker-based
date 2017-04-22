#
# Copyright (C) 2017 Conjur Inc
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

class Conjur::Command::Policies < Conjur::Command
  desc "Manage policies"
  command :policy do |p|
    p.desc "Load a policy"
    p.arg_name "POLICY FILENAME"
    p.command :load do |c|
      c.desc "Fully replace the existing policy, deleting any data that is not declared in the new policy."
      c.switch :replace

      c.desc "Allow explicit deletion statements in the policy."
      c.switch :delete
      
      c.action do |global_options,options,args|
        policy_id = require_arg(args, 'POLICY')
        filename = require_arg(args, 'FILENAME')
        policy = if filename == '-'
          STDIN.read
        else
          require 'open-uri'
          open(filename).read
        end
        
        method = if options[:replace]
          Conjur::API::POLICY_METHOD_PUT
        elsif options[:delete]
          Conjur::API::POLICY_METHOD_PATCH
        else
          Conjur::API::POLICY_METHOD_POST
        end
        
        result = api.load_policy policy_id, policy, method: method
        $stderr.puts "Loaded policy '#{policy_id}'"
        puts JSON.pretty_generate(result)
      end
    end
  end
end
