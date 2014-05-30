require 'spec_helper'
require 'conjur/conjurenv'
require 'tempfile'


shared_examples_for "processes environment definition" do |cmd, options|
  before {  # suspend all interaction with the environment
    Kernel.stub(:system).and_return(true) 
  }
  let(:stub_object) { double(obtain:{}, check:{}) }

  describe_command "env:#{cmd} #{options}" do
    it "uses .conjurenv file by default" do
      Conjur::Env.should_receive(:new).with(file:".conjurenv").and_return(stub_object)
      invoke
    end
  end

  describe_command "env:#{cmd} -c somefile #{options}" do
    it "uses desired file" do
      Conjur::Env.should_receive(:new).with(file:"somefile").and_return(stub_object)
      invoke
    end
  end
  
  describe_command "env:#{cmd} --yaml someyaml #{options}" do
    it "uses inline yaml" do
      Conjur::Env.should_receive(:new).with(yaml:"someyaml").and_return(stub_object)
      invoke
    end
  end

  describe_command "env:#{cmd} -c somefile --yaml someyaml #{options}" do
    it "refuses to accept mutually exclusive options" do      
      Conjur::Env.should_not_receive(:new)
      expect { invoke }.to raise_error /Options -c and --yaml can not be provided together/
    end
  end
end

describe Conjur::Command::Env, logged_in: true do

  let(:stub_env)    { double() }
  describe ":check" do
    it_behaves_like "processes environment definition", "check", ''

    describe_command "env:check" do
      before { Conjur::Env.should_receive(:new).and_return(stub_env) }
      describe "without api errors" do
        let(:stub_result) {  { "a" => :available, "b"=> :available } }
        before {
          stub_env.should_receive(:check).with(an_instance_of(Conjur::API)).and_return(stub_result)
        }

        describe "if all variables are available" do
          it "prints #check result to the output" do
            expect { invoke }.to write "a: available\nb: available\n"
          end

          it "does not crash" do
            expect { invoke }.to_not raise_error
          end
        end

        describe "if some variables are unavailable" do
          let(:stub_result) {  { "a" => :unavailable, "b"=> :available } }
          it "prints #check result to the output" do
            expect { invoke rescue true }.to write "a: unavailable\nb: available\n"
          end
          it "crashes in the end" do
            expect { invoke  }.to raise_error "Some variables are not available"
          end
        end
      end
      it 'does not rescue unexpected errors' do
        stub_env.should_receive(:check).with(an_instance_of(Conjur::API)).and_return { raise "Custom error" }
        expect { invoke }.to raise_error "Custom error"
      end
    end
  end

  describe ":run" do
    it_behaves_like "processes environment definition", "run","-- extcmd"
    describe_command "env:run" do
      it 'fails because of missing argument' do 
        Kernel.should_not_receive(:system)
        expect { invoke }.to raise_error "External command with optional arguments should be provided" 
      end 
    end
    describe_command "env:run -- extcmd --arg1 arg2" do
      before { 
        Conjur::Env.should_receive(:new).and_return(stub_env)
      }

      describe "if no errors are raised" do
        let(:stub_result) { { "a" => "value_a", "b" => "value_b" } }
        before {
          stub_env.should_receive(:obtain).with(an_instance_of(Conjur::API)).and_return(stub_result)
        }
        it "performs #exec with environment (names in uppercase)" do
          Kernel.should_receive(:system).with({"A"=>"value_a", "B"=>"value_b"}, "extcmd", "--arg1","arg2").and_return(true)
          invoke 
        end
      end
      it "does not rescue unexpected errors" do
        stub_env.should_receive(:obtain).with(an_instance_of(Conjur::API)).and_return { raise "Custom error" } 
        expect { invoke }.to raise_error "Custom error"
      end
    end
  end

  describe ":template" do
    context do 
      before { # prevent real operation
        File.stub(:readable?).with("config.erb").and_return(true)
        File.stub(:read).with("config.erb").and_return("template")
        ERB.stub(:new).and_return(double(result:''))
        Tempfile.stub(:new).and_return(double(write: true, close: true, path: 'somepath'))
        FileUtils.stub(:copy).and_return(true)
      }
      it_behaves_like "processes environment definition", "template","config.erb"
    end
    describe_command "env:template" do
      it 'fails because of missing argument' do 
        Tempfile.should_not_receive(:new)
        expect { invoke }.to raise_error "Location of readable ERB template should be provided"
      end 
    end
    describe_command "env:template config.erb" do
      let(:erb_template) { """
variable <%= conjurenv['a'] %>
other variable <%= conjurenv['b'] %>
"""
      }
      before { 
        File.stub(:readable?).with("config.erb").and_return(true)
        File.stub(:read).with("config.erb").and_return(erb_template)
        Conjur::Env.should_receive(:new).and_return(stub_env)
        stub_env.should_receive(:obtain).with(an_instance_of(Conjur::API)).and_return( {"a"=>"value_a","b"=>"value_b","c"=>"value_c"} )
      }

      it "creates persistent tempfile, saves rendered template into it, prints out name of the file" do 
        stubpath="/tmp/temp.file"
        tempfile=double(close: true, path: stubpath)
        Tempfile.should_receive(:new).and_return(tempfile)
        tempfile.should_receive(:write).with("\nvariable value_a\nother variable value_b\n")  
        FileUtils.should_receive(:copy).with(stubpath,stubpath+'.saved') # avoid garbage collection
        expect { invoke }.to write stubpath+".saved"
      end
    end
  end
end
