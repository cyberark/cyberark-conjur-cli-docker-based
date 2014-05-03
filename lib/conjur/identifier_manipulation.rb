module Conjur
  module IdentifierManipulation
    # injects account into 2-tokens id
    def full_resource_id id
      parts = id.split(':') unless id.nil? 
      if id.blank? or parts.size < 2
        raise "Expecting at least two tokens in #{id}"
      end
      if parts.size == 2
        id = [conjur_account, parts].flatten.join(":")
      end
      id
    end

    # removes accounts from 3+-tokens id, extracts kind
    def get_kind_and_id_from_args args, argname='id'
      flat_id = require_arg(args, argname)
      tokens=flat_id.split(':')
      raise "At least 2 tokens expected in #{flat_id}" if tokens.size<2
      tokens.shift if tokens.size>=3 # get rid of account
      kind=tokens.shift.gsub('-','_')
      [kind, tokens.join(':')]
    end

    # removes kind for specific commands
    def remove_kind_from_id id, kindname
      tokens = id.split ':' unless id.nil?
      raise "At largest 2 tokens expected in #{id}" if tokens.size > 2
      if tokens.size == 2
        raise "Expecting kind name is only #{kindname}" unless tokens[0] == kindname
        id = tokens[1]
      else
        id = tokens.shift
      end
      id
    end

    # adds kind for specific commands
    def add_kind_to_id id, kindname
      tokens = id.split ':' unless id.nil?
      if tokens.count == 1
        id = [kindname, tokens].join(':')
      end
      id
    end

    def conjur_account
      Conjur::Core::API.conjur_account
    end
  end
end