require 'spec_helper'

shared_context "Existing file" do
  before { 
    File.stub(:exists?).and_return(true)
    File.stub(:readlines).and_return(contents)
  }
end

shared_context "No invocation" do
  before {
    Kernel.stub(:exec).and_return(true)
  }
end

shared_context "Stub Conjur vars" do
  let(:contents) { [ "# this is a comment\n", 
                     "variable_a=conjur/variable/1",
                     "variable_b=conjur/variable/2"
                   ]}

  let(:conjur_variables) { { 
                    "conjur/variable/1"=>1,
                    "conjur/variable/2"=>2
                 }}

  before {
    api.stub(:variable) { |varname| double(value: conjur_variables[varname]) }
    api.stub(:variables).with(["conjur/variable/1","conjur/variable/2"]) { conjur_variables }
  }
end

describe Conjur::Command::Env, logged_in: true do

  let(:contents) { [ "VAR1=val2\n", "VAR3=val4\n" ] }

  describe "(Reading files)" do
    let(:variable_value) { "x" }
    let(:environment_variables) { {x: 1, y: 2} }
    include_context "No invocation"
    before(:each) do
      File.stub(:exists?).and_return(true)
      api.stub(:variable).and_return( double({value: variable_value}) )
      api.stub(:environment).and_return(double({attributes: {variables: environment_variables} }))
    end

    describe_command "env -f somefile -- extcommand" do
      it 'reads file from  filename option' do
        File.should_receive(:readlines).with("somefile").and_return(contents)
        invoke
      end 
    end
    describe_command "env -- extcommand" do
      it 'reads default file .conjurenv' do
        File.should_receive(:readlines).with(".conjurenv").and_return(contents)
        invoke
      end
    end
  end


  describe "(Immediate failures without API calls)" do

    describe_command "env -f unexisting_file" do
      it 'file does not exist' do
        api.should_not_receive(:variable)
        expect { invoke }.to raise_error "File does not exist: unexisting_file"
      end
    end

    describe_command "env" do
      include_context "Existing file"
      it "no external command is provided" do
        api.should_not_receive(:variable)
        expect { invoke }.to raise_error("External command should be provided (with optional args)")
      end 
    end

    describe_command "env -- somecommand" do
      include_context "Existing file"
      describe "malformed file" do
         let(:contents) { ["abbracadabbra"] }
         it "file is malformed" do
           api.should_not_receive(:variable)
           expect { invoke }.to raise_error(/Malformed line in .* \(key=value pairs are expected\): abbracadabbra/)
         end
      end
    end
  end

  describe "Obtaining variables via API" do
    describe_command "env -- extcommand" do

      include_context "Existing file"
      include_context "Stub Conjur vars"
      include_context "No invocation"

      it "in single call" do
        api.should_receive(:variables).with(["conjur/variable/1","conjur/variable/2"]).and_return(conjur_variables)
        api.should_not_receive(:variable)
        invoke
      end

      it 'one by one, if single call fails' do
        api.should_receive(:variables).with(["conjur/variable/1","conjur/variable/2"]) { raise "404" }
        api.should_receive(:variable).with("conjur/variable/1").and_return( double(value: 1) )
        api.should_receive(:variable).with("conjur/variable/2").and_return( double(value: 2) )
        invoke
      end

      describe "if any variable is not accessible" do
        it 'fails' do
          api.stub(:variables).with(["conjur/variable/1","conjur/variable/2"]) { raise "404" }
          api.stub(:variable).with("conjur/variable/1") { raise "Something wrong" }
          expect { invoke }.to raise_error "Something wrong"
        end
      end
    end
  end

  describe "Command execution context" do
    include_context "Existing file"
    include_context "Stub Conjur vars"

    describe_command "env -- extcommand --extoption1 value1 arg2" do
      it 'external command is executed with unparsed args' do
        Kernel.should_receive(:exec).with(an_instance_of(Hash), ["extcommand","--extoption1","value1","arg2"])
        invoke
      end

      describe 'environment contains expected variables (uppercased)' do
        let(:expected_env) { {"VARIABLE_A"=>1, "VARIABLE_B"=>2} }
          it 'when variables obtained in single call' do
            Kernel.should_receive(:exec).with(expected_env,anything())
            invoke  
          end
          it 'when variables obtained one by one' do    
            api.stub(:variables) { raise "404" }
            Kernel.should_receive(:exec).with(expected_env,anything())
            invoke  
          end
      end

       
    end

  end
end
