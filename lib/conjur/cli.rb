require 'gli'

module Conjur
  class Cli
    extend GLI::App

    commands_from 'conjur/command'
  end
end
