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
require 'spec_helper'
require 'conjur/command/pubkeys'

describe Conjur::Command::Pubkeys, logged_in: true do
  describe_command "pubkeys:show alice" do
    it "calls api.public_keys('alice') and prints the result" do
      expect(described_class.api).to receive(:public_keys).with('alice').and_return "a public key"
      expect{ invoke }.to write("a public key")
    end
  end
  
  describe_command "pubkeys:names alice" do
    let(:keys){ ["x y foo", "x y bar"].join("\n") }
    let(:names){ "bar\nfoo" }
    it "calls api.public_keys('alice') and prints the names" do
      expect(described_class.api).to receive(:public_keys).with('alice').and_return keys
      expect{ invoke }.to write(names) 
    end
  end
  
  describe_command "pubkeys:add alice data" do
    it "calls api.add_public_key('alice', 'data') and prints the key name" do
      expect(described_class.api).to receive(:add_public_key).with('alice', 'data')
      expect{ invoke }.to write("Public key 'data' added")
    end
  end
  
  describe_command "pubkeys:add alice @id_rsa.pub" do
    let(:file_contents){ "ssh-rsa blahblah keyname" }
    it "calls api.add_public_key('alice', data) and prints the key name" do
      expect(File).to receive(:read) do |filename|
        expect(filename).to end_with("id_rsa.pub")
        file_contents
      end
      expect(described_class.api).to receive(:add_public_key).with('alice', file_contents)
      expect{ invoke }.to write("Public key 'keyname' added")
    end
  end
  
  describe_command "pubkeys:add alice" do
    let(:stdin_contents){ "ssh-rsa blahblah keyname" }
    it "calls api.add_public_key('alice', stdin) and prints the key name" do
      expect(STDIN).to receive(:read).and_return(stdin_contents)
      expect(described_class.api).to receive(:add_public_key).with('alice', stdin_contents)
      expect{ invoke }.to write("Public key 'keyname' added")
    end
  end
  
  describe_command "pubkeys:delete alice keyname" do
    it "calls api.delete_public_key('alice', 'keyname')" do
      expect(described_class.api).to receive(:delete_public_key).with("alice", "keyname")
      expect{ invoke }.to write("Public key 'keyname' deleted")
    end
  end
end
