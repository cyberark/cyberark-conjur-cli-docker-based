require 'spec_helper'
require 'conjur/conjurenv'

describe Conjur::Env do

  describe "#initialize" do

    describe "requires either :file or :yaml parameter" do
      before { 
        Conjur::Env.any_instance.should_not_receive(:parse) 
      }
      it "fails if both options are provided" do
        expect { Conjur::Env.new(file: 'f', yaml: 'y') }.to raise_error ":file and :yaml options can not be provided together"
      end   
      it "fails if neither option is provided" do  
        expect { Conjur::Env.new() }.to raise_error "either :file or :yaml option is mandatory"
      end
      it "fails if :yaml option is empty or is not a string" do
        expect { Conjur::Env.new(yaml: "") }.to raise_error ":yaml option should be non-empty string"
        expect { Conjur::Env.new(yaml: nil) }.to raise_error ":yaml option should be non-empty string"
        expect { Conjur::Env.new(yaml: 2) }.to raise_error ":yaml option should be non-empty string"
      end
      it "fails if :file option is empty or is not a string"do
        expect { Conjur::Env.new(file: "") }.to raise_error ":file option should be non-empty string"
        expect { Conjur::Env.new(file: nil) }.to raise_error ":file option should be non-empty string"
        expect { Conjur::Env.new(file: 2) }.to raise_error ":file option should be non-empty string"
      end
    end

    describe "with correct parameters" do

      let(:parsed) { :parsed_structure_stub }

      describe "if :file parameter provided" do
        it "does not catch any errors from File.read" do
          Conjur::Env.any_instance.should_not_receive(:parse) 
          File.stub(:read).with('unexisting').and_return { raise "Custom error" }
          expect { Conjur::Env.new(file: 'unexisting') }.to raise_error "Custom error"
        end 

        it "if file is readable, passes contents to #parse and stores result in @definition attribute" do 
          File.should_receive(:read).with("somefile").and_return(:file_contents) 
          Conjur::Env.any_instance.should_receive(:parse).with(:file_contents).and_return(:stub_parsed) 
          Conjur::Env.new(file:"somefile").instance_variable_get("@definition").should == :stub_parsed
        end
      end
      it "if :yaml parameter provided, passes it to #parse and stores result in @definition attribute" do
        Conjur::Env.any_instance.should_receive(:parse).with("custom yaml").and_return(:stub_parsed)
        Conjur::Env.new(yaml:"custom yaml").instance_variable_get("@definition").should == :stub_parsed
      end
    end
  end

  describe "#parse (called from 'initialize')" do

    it 'parses input as YAML and does not hide YAML errors' do
      YAML.should_receive(:load).with("custom yaml").and_return { raise "Custom error" }
      expect { Conjur::Env.new(yaml: "custom yaml") }.to raise_error "Custom error"
    end

    it "fails unless YAML represents a Hash" do
      expect { Conjur::Env.new(yaml: "[ 1,2,3 ]") }.to raise_error "Definition should be a Hash"
    end

    it "fails if values are not literal, !tmp or !var" do
      expect { Conjur::Env.new(yaml: "{a: literal, b: !tmp tempfile, c: !var conjurvar, d: { x: another literal }}") }.to raise_error /^Definition can not include values of types/
      expect { Conjur::Env.new(yaml: "{a: literal, b: !tmp tempfile, c: !var conjurvar}") }.to_not raise_error 
    end 

    it 'does not allow empty values for !tmp and !var' do
      expect { Conjur::Env.new(yaml: "{a: literal, b: !tmp , c: !var conjurvar }") }.to raise_error "ConjurTempfile requires a parameter"
      expect { Conjur::Env.new(yaml: "{a: literal, b: !tmp tempfile, c: !var }") }.to raise_error "ConjurVariable requires a parameter"
      expect { Conjur::Env.new(yaml: "{a: literal, b: !tmp tempfile, c: !var conjurvar}") }.to_not raise_error 
    end

    it "Returns hash consisting of literals, ConjurTempfile and ConjurVariable objects" do
      result = Conjur::Env.new(yaml: "{a: literal, b: !tmp 'sometmp', c: !var 'somevar'}").instance_variable_get("@definition")
      result.keys.sort.should == ["a","b","c"]
      result["a"].should == 'literal'
      result["b"].should be_a_kind_of(Conjur::Env::ConjurTempfile)
      result["c"].should be_a_kind_of(Conjur::Env::ConjurVariable)
    end
  end

  describe "#obtain", logged_in: true do
    let(:subject) { Conjur::Env.new(yaml: "{a: literal, b: !tmp tempfile, c: !var conjurvar}") }
    before { 
      api.stub(:variable_values).with(["tempfile","conjurvar"]).and_return({"tempfile" => "stubtemp", "conjurvar" => "stubvar" })
    }

    it "requests variable_values with list of !var and !tmp values" do    
      Conjur::Env::ConjurTempfile.any_instance.stub(:evaluate).and_return(:stub_value) # avoid tempfiles creation
      api.should_receive(:variable_values).with(["tempfile","conjurvar"]).and_return({"tempfile" => "stub1", "conjurvar" => "stub2" })
      subject.obtain(api)
    end

    it 'does not suppress api errors' do  
      api.stub(:variable_values).and_return { raise "Custom API error" }
      expect { subject.obtain(api) }.to raise_error "Custom API error" 
    end

    describe "for !tmp creates temporary files with Conjur variable value" do
      it "in /dev/shm if it exists" do  
        tempfile = double(path: '/dev/shm/newfile', close: true)
        File.should_receive(:directory?).with("/dev/shm").and_return(true)
        File.should_receive(:writable?).with("/dev/shm").and_return(true)
        Tempfile.should_receive(:new).with("conjur","/dev/shm").and_return(tempfile)
        tempfile.should_receive(:write).with("stubtemp")
        subject.obtain(api)
      end
      it "otherwise uses Tempfile defaults" do
        tempfile = double(path: '/tmp/newfile', close: true)
        File.should_receive(:directory?).with("/dev/shm").and_return(false)
        Tempfile.should_receive(:new).with("conjur").and_return(tempfile)
        tempfile.should_receive(:write).with("stubtemp")
        subject.obtain(api)
      end
    end

    describe "returns hash consisting of original keys and following values" do
      before {  
        tempfile=double(path:"/stub/tempfile",write: true, close: true)
        File.stub(:directory?).with("/dev/shm").and_return(true)
        File.stub(:writable?).with("/dev/shm").and_return(true)
        Tempfile.stub(:new).with("conjur","/dev/shm").and_return(tempfile)
      }
      let(:result) { subject.obtain(api) }

      it 'literals' do
        result.should include("a"=>"literal") 
      end
      it '!tmp: names of temp files' do
        result.should include("b"=>"/stub/tempfile")
      end
      it '!var: variable values' do
        result.should include("c"=>"stubvar")
      end
    end
  end

  describe "#check", logged_in: true do

    let(:subject) { Conjur::Env.new(yaml: "{a: literal, b: !tmp tempfile_b, c: !var conjurvar_c, d: !tmp tempfile_d, e: !var conjurvar_e }") }
    before { 
      api.should_not_receive(:variable_values) 
      Tempfile.should_not_receive(:new)
    }
    let(:permitted)  { double(permitted?:true) }
    let(:restricted) { double(permitted?:false) }

    it "requests resource 'execute' permission for each !var and !tmp value" do
      api.should_receive(:resource).with("variable:tempfile_b").and_return(permitted) 
      api.should_receive(:resource).with("variable:conjurvar_c").and_return(permitted) 
      api.should_receive(:resource).with("variable:tempfile_d").and_return(permitted) 
      api.should_receive(:resource).with("variable:conjurvar_e").and_return(permitted) 
      permitted.should_receive(:permitted?).exactly(4).times.with(:execute).and_return(true)
      subject.check(api)
    end

    it 'does not rescue from unexpected api errors' do  
      api.should_receive(:resource).with("variable:tempfile_b").and_return { raise "Custom error" }
      expect { subject.check(api) }.to raise_error "Custom error"
    end

    it "returns Hash consisting of original keys and following statuses: :literal, :available, :unavailable" do
      api.should_receive(:resource).with("variable:tempfile_b").and_return(permitted) 
      api.should_receive(:resource).with("variable:conjurvar_c").and_return(restricted) 
      api.should_receive(:resource).with("variable:tempfile_d").and_return(restricted) 
      api.should_receive(:resource).with("variable:conjurvar_e").and_return(permitted) 
      
      result = subject.check(api).should == { "a" => :literal, 
                                              "b" => :available, 
                                              "c" => :unavailable, 
                                              "d" => :unavailable, 
                                              "e" => :available 
                                            }
    end
  end
    
end
