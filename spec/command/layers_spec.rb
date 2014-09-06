require 'spec_helper'

describe Conjur::Command::Layers, logged_in: true do
  let(:layer) { double(:layer) }
  
  [ "layer hosts add", "layer:hosts:add" ].each do |cmd|
    describe_command "#{cmd} the-layer the-host" do
      it "adds a host id to the layer" do
        expect_any_instance_of(Conjur::API).to receive(:layer).with("the-layer").and_return layer
        expect(layer).to receive(:add_host).with("the-account:host:the-host")
  
        expect { invoke }.to write("Host added")
      end
    end
    describe_command "#{cmd} the-layer host:the-host" do
      it "adds a qualified host id to the layer" do
        expect_any_instance_of(Conjur::API).to receive(:layer).with("the-layer").and_return layer
        expect(layer).to receive(:add_host).with("host:the-host")
  
        expect { invoke }.to write("Host added")
      end
    end
  end

  [ "layer hosts remove", "layer:hosts:remove" ].each do |cmd|
    describe_command "#{cmd} the-layer the-host" do
      it "adds a host to the layer" do
        expect_any_instance_of(Conjur::API).to receive(:layer).with("the-layer").and_return layer
        expect(layer).to receive(:remove_host).with("the-account:host:the-host")
  
        expect { invoke }.to write("Host removed")
      end
    end
  end
end
