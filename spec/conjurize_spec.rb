require 'spec_helper'
require 'conjur/conjurize'

describe Conjur::Conjurize, logged_in: true do
  describe_conjurize "foo" do
    it "should foo" do
      invoke
    end
  end
end
