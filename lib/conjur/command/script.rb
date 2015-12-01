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
require 'conjur/command/dsl_command'

require 'etc'
require 'socket'
require 'active_support/core_ext/object'

class Conjur::Command::Script < Conjur::DSLCommand
  class << self
    def default_collection_user
      # More accurate than Etc.getlogin
      Etc.getpwuid(Process.uid).try(&:name) || Etc.getlogin
    end

    def default_collection_hostname
      Socket.gethostname
    end

    def default_collection_name
      [ default_collection_user, default_collection_hostname ].join('@')
    end
  end

  desc "Execute Conjur DSL scripts"
  command :script do |script|
    script.desc "Run a Conjur DSL script"
    script.arg_name "script"
    script.command :execute do |c|
      acting_as_option(c)

      c.desc "Script collection (target environment)"
      c.arg_name "collection"
      c.default_value default_collection_name
      c.flag [:collection]


      c.desc "Load context from this config file, and save it when finished. The file permissions will be 0600 by default."
      c.arg_name "FILE"
      c.flag [:c, :context]

      c.action do |global_options,options,args|
        collection = options[:collection] || default_collection_name

        run_script args, options do |runner, &block|
          runner.scope collection do
            block.call
          end
        end
      end
    end
  end
end
