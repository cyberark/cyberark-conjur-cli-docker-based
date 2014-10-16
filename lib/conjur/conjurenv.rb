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
require 'conjur/api'
require 'yaml'

module Conjur
  class Env

    class CustomTag
      def initialize id 
        raise "#{self.class.name.split('::').last} requires a parameter" if id.to_s.empty?
        @id=id
      end
      def gsub! pattern, replace
        @id.gsub! pattern, replace
      end
      def init_with(coder)
        initialize(coder.scalar)
      end
      def conjur_id
        @id
      end
    end

    class ConjurVariable < CustomTag
      def evaluate value
        raise "variable #{id} exists but doesn't have a value" if value.nil?
        value.chomp
      end
    end

    class ConjurTempfile < CustomTag
      def evaluate value
        @tempfile = if File.directory?("/dev/shm") and File.writable?("/dev/shm") 
                      Tempfile.new("conjur","/dev/shm")
                    else  
                      Tempfile.new("conjur")
                    end
        @tempfile.write(value)
        @tempfile.close
        @tempfile.path
      end
    end

    def initialize(options={})
      raise ":file and :yaml options can not be provided together" if ( options.has_key?(:file) and options.has_key?(:yaml) )

      yaml = if options.has_key?(:yaml) 
        raise ":yaml option should be non-empty string" unless options[:yaml].kind_of?(String)
        raise ":yaml option should be non-empty string" if options[:yaml].empty?
        options[:yaml]
      elsif options.has_key?(:file)
        raise ":file option should be non-empty string" unless options[:file].kind_of?(String)
        raise ":file option should be non-empty string" if options[:file].empty?
        File.read(options[:file])
      else
        raise "either :file or :yaml option is mandatory"
      end
      parse_arguments = [ yaml ]
      parse_arguments << options[:substitutions] if options[:substitutions]
      @definition = parse(*parse_arguments)
    end

    def parse(yaml, substitutions = {})
      YAML.add_tag("!var", ConjurVariable)
      YAML.add_tag("!tmp", ConjurTempfile)
      definition = YAML.load(yaml)
      raise "Definition should be a Hash" unless definition.kind_of?(Hash)
      # convert fixnums to literals -- to make definitions of e.g. ports more convenient
      definition.keys.select { |k| definition[k].kind_of? Fixnum }.each { |k| definition[k]="#{definition[k]}" }
      bad_types = definition.values.select { |v| not (v.kind_of?(String) or v.kind_of?(CustomTag)) }.map {|v| v.class}.uniq
      raise "Definition can not include values of types: #{bad_types}" unless bad_types.empty?
      definition.inject({}) do |memo,e| 
        key, value = e
        substitutions.each do |k,v|
          value.gsub! k, v
        end
        memo[key] = value
        memo
      end
      definition
    end

    def obtain(api)
      runtime_environment={}
      variable_ids= @definition.values.map { |v| v.conjur_id rescue nil }.compact
      conjur_values=api.variable_values(variable_ids)
      @definition.each { |environment_name, reference| 
        runtime_environment[environment_name]= if reference.respond_to?(:evaluate)
                                                  reference.evaluate( conjur_values[reference.conjur_id] )
                                               else
                                                  reference # is a literal value
                                               end
      }
      return runtime_environment
    end

    def check(api)
      Hash[ 
        @definition.map { |k,v| 

          status = if v.respond_to? :conjur_id
                     if api.resource("variable:"+v.conjur_id).permitted?(:execute)
                       :available   
                     else
                       :unavailable
                     end
                   else
                     :literal
                   end
 
          [ k, status ]
        }
      ]
    end

  end
end
