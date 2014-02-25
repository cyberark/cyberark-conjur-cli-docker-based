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
require 'conjur/command/dsl_command'

class Conjur::Command::Policy < Conjur::DSLCommand
  self.prefix = :policy
  
  class << self
    def default_collection_user
      ENV['USER']
    end
    
    def default_collection_hostname
      ENV['HOSTNAME'] || `hostname`
    end
  
    def default_collection_name
      [ default_collection_user, default_collection_hostname ].join('@')
    end
  end

  desc "Load a policy from Conjur DSL"
  long_desc <<-DESC
This method is EXPERIMENTAL and subject to change

Loads a Conjur policy from DSL, applying particular conventions to the role and resource
ids. 

The first path element of each id is the collection. Policies are separated into collections
according to software development lifecycle. The default collection for a policy is $USER@$HOSTNAME,
in other words, the username and hostname on which the policy is created. This is approriate for
policy development and local testing. Once tested, policies can be created in more official 
environments such as ci, stage, and production. 

The second path element of each id is the policy name and version, following the convention
policy-x.y.z, where x, y, and z are the semantic version of the policy.

Next, each policy creates a policy role and policy resource. The policy resource is used to store
annotations on the policy. The policy role becomes the owner of the owned policy assets. The
--as-group and --as-role options can be used to set the owner of the policy role. The default
owner of the policy role is the logged-in user (you), as always.
  DESC
  arg_name "(policy-file | STDIN)"
  command :load do |c|
    acting_as_option(c)
    
    c.desc "Policy collection (default: #{default_collection_name})"
    c.arg_name "collection"
    c.flag [:collection]
    
    c.desc "Policy id (required)"
    c.arg_name "id"
    c.flag [:i, :id]
    
    c.desc "Policy name"
    c.arg_name "name"
    c.flag [:n, :name]
    
    c.desc "Policy version number (required)"
    c.arg_name "version"
    c.flag [:v, :version]
    
    c.desc "Load context from this config file, and save it when finished. The file permissions will be 0600 by default."
    c.arg_name "context"
    c.flag [:c, :context]
    
    c.action do |global_options,options,args|
      [ :id, :version ].each do |arg|
        exit_now! "#{arg} is required" unless options[arg]
      end
      
      collection = options[:collection] || default_collection_name
      policy_id = [ options[:id], options[:version] ].join('-')
      policy_annotations = {}
      policy_annotations[:name] = options[:name] if options[:name]
      
      run_script args, options do |runner, &block|
        runner.scope collection do
          runner.role "policy", policy_id do
            runner.owns do
              runner.resource "policy", policy_id, annotations: policy_annotations

              block.call
            end
          end
        end
      end
    end
  end
end