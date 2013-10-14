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

    def conjur_account
      Conjur::Core::API.conjur_account
    end
  end
end