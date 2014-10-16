require 'spec_helper'
require 'conjur/conjurenv'

describe Conjur::Env do

  describe "#initialize" do

    describe "requires either :file or :yaml parameter" do
      before { 
        expect_any_instance_of(Conjur::Env).not_to receive(:parse) 
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
          expect_any_instance_of(Conjur::Env).not_to receive(:parse) 
          allow(File).to receive(:read).with('unexisting') { raise "Custom error" }
          expect { Conjur::Env.new(file: 'unexisting') }.to raise_error "Custom error"
        end 

        it "if file is readable, passes contents to #parse and stores result in @definition attribute" do 
          expect(File).to receive(:read).with("somefile").and_return(:file_contents) 
          expect_any_instance_of(Conjur::Env).to receive(:parse).with(:file_contents).and_return(:stub_parsed) 
          expect(Conjur::Env.new(file:"somefile").instance_variable_get("@definition")).to eq(:stub_parsed)
        end
      end
      it "if :yaml parameter provided, passes it to #parse and stores result in @definition attribute" do
        expect_any_instance_of(Conjur::Env).to receive(:parse).with("custom yaml").and_return(:stub_parsed)
        expect(Conjur::Env.new(yaml:"custom yaml").instance_variable_get("@definition")).to eq(:stub_parsed)
      end
    end
  end

  describe "#parse (called from 'initialize')" do

    it 'parses input as YAML and does not hide YAML errors' do
      expect(YAML).to receive(:load).with("custom yaml") { raise "Custom error" }
      expect { Conjur::Env.new(yaml: "custom yaml") }.to raise_error "Custom error"
    end

    it "fails unless YAML represents a Hash" do
      expect { Conjur::Env.new(yaml: "[ 1,2,3 ]") }.to raise_error "Definition should be a Hash"
    end

    it "fails if values are not literal, number, !tmp or !var" do
      expect { Conjur::Env.new(yaml: "{a: literal, b: !tmp tempfile, c: !var conjurvar, d: { x: another literal }}") }.to raise_error /^Definition can not include values of types/
      expect { Conjur::Env.new(yaml: "{a: literal, b: 123, c: !tmp tempfile, d: !var conjurvar}") }.to_not raise_error 
    end 

    it 'does not allow empty values for !tmp and !var' do
      expect { Conjur::Env.new(yaml: "{a: literal, b: !tmp , c: !var conjurvar }") }.to raise_error "ConjurTempfile requires a parameter"
      expect { Conjur::Env.new(yaml: "{a: literal, b: !tmp tempfile, c: !var }") }.to raise_error "ConjurVariable requires a parameter"
      expect { Conjur::Env.new(yaml: "{a: literal, b: !tmp tempfile, c: !var conjurvar}") }.to_not raise_error 
    end

    it "Returns hash consisting of literals, ConjurTempfile and ConjurVariable objects" do
      result = Conjur::Env.new(yaml: "{a: literal, b: !tmp 'sometmp', c: !var 'somevar'}").instance_variable_get("@definition")
      expect(result.keys.sort).to eq(["a","b","c"])
      expect(result["a"]).to eq('literal')
      expect(result["b"]).to be_a_kind_of(Conjur::Env::ConjurTempfile)
      expect(result["b"].conjur_id).to eq('sometmp')
      expect(result["c"]).to be_a_kind_of(Conjur::Env::ConjurVariable)
      expect(result["c"].conjur_id).to eq('somevar')
    end
    
    it "Accepts empty string substitution" do
      substitutions = {
      }
      result = Conjur::Env.new(yaml: "{a: $foo, b: !tmp '$foo$foo$bar', c: !var '$foo$bar'}", substitutions: substitutions).instance_variable_get("@definition")
      expect(result["a"]).to eq('$foo')
      expect(result["b"].conjur_id).to eq('$foo$foo$bar')
      expect(result["c"].conjur_id).to eq('$foo$bar')
    end

    it "Performs requested string substitution" do
      substitutions = {
        "$foo" => "alice",
        "$bar" => "bob"
      }
      result = Conjur::Env.new(yaml: "{a: $foo, b: !tmp '$foo$foo$bar', c: !var '$foo$bar'}", substitutions: substitutions).instance_variable_get("@definition")
      expect(result["a"]).to eq('alice')
      expect(result["b"].conjur_id).to eq('alicealicebob')
      expect(result["c"].conjur_id).to eq('alicebob')
    end

    it "Converts numbers to string literals" do
      result = Conjur::Env.new(yaml: "{a: 123}").instance_variable_get("@definition")
      expect(result["a"]).to eq("123")
    end

  end

  describe "#obtain", logged_in: true do
    let(:subject) { Conjur::Env.new(yaml: "{a: literal, b: !tmp tempfile, c: !var conjurvar}") }
    before { 
      allow(api).to receive(:variable_values).with(["tempfile","conjurvar"]).and_return({"tempfile" => "stubtemp", "conjurvar" => "stubvar" })
    }

    it "requests variable_values with list of !var and !tmp values" do    
      allow_any_instance_of(Conjur::Env::ConjurTempfile).to receive(:evaluate).and_return(:stub_value) # avoid tempfiles creation
      expect(api).to receive(:variable_values).with(["tempfile","conjurvar"]).and_return({"tempfile" => "stub1", "conjurvar" => "stub2" })
      subject.obtain(api)
    end

    it 'does not suppress api errors' do  
      allow(api).to receive(:variable_values) { raise "Custom API error" }
      expect { subject.obtain(api) }.to raise_error "Custom API error" 
    end

    describe "for !tmp creates temporary files with Conjur variable value" do
      it "in /dev/shm if it exists" do  
        tempfile = double(path: '/dev/shm/newfile', close: true)
        expect(File).to receive(:directory?).with("/dev/shm").and_return(true)
        expect(File).to receive(:writable?).with("/dev/shm").and_return(true)
        expect(Tempfile).to receive(:new).with("conjur","/dev/shm").and_return(tempfile)
        expect(tempfile).to receive(:write).with("stubtemp")
        subject.obtain(api)
      end
      it "otherwise uses Tempfile defaults" do
        tempfile = double(path: '/tmp/newfile', close: true)
        expect(File).to receive(:directory?).with("/dev/shm").and_return(false)
        expect(Tempfile).to receive(:new).with("conjur").and_return(tempfile)
        expect(tempfile).to receive(:write).with("stubtemp")
        subject.obtain(api)
      end
    end

    describe "returns hash consisting of original keys and following values" do
      before {  
        tempfile=double(path:"/stub/tempfile",write: true, close: true)
        allow(File).to receive(:directory?).with("/dev/shm").and_return(true)
        allow(File).to receive(:writable?).with("/dev/shm").and_return(true)
        allow(Tempfile).to receive(:new).with("conjur","/dev/shm").and_return(tempfile)
      }
      let(:result) { subject.obtain(api) }

      it 'literals' do
        expect(result).to include("a"=>"literal") 
      end
      it '!tmp: names of temp files' do
        expect(result).to include("b"=>"/stub/tempfile")
      end
      it '!var: variable values' do
        expect(result).to include("c"=>"stubvar")
      end
    end
  end

  describe "#check", logged_in: true do

    let(:subject) { Conjur::Env.new(yaml: "{a: literal, b: !tmp tempfile_b, c: !var conjurvar_c, d: !tmp tempfile_d, e: !var conjurvar_e }") }
    before { 
      expect(api).not_to receive(:variable_values) 
      expect(Tempfile).not_to receive(:new)
    }
    let(:permitted)  { double(permitted?:true) }
    let(:restricted) { double(permitted?:false) }

    it "requests resource 'execute' permission for each !var and !tmp value" do
      expect(api).to receive(:resource).with("variable:tempfile_b").and_return(permitted) 
      expect(api).to receive(:resource).with("variable:conjurvar_c").and_return(permitted) 
      expect(api).to receive(:resource).with("variable:tempfile_d").and_return(permitted) 
      expect(api).to receive(:resource).with("variable:conjurvar_e").and_return(permitted) 
      expect(permitted).to receive(:permitted?).exactly(4).times.with(:execute).and_return(true)
      subject.check(api)
    end

    it 'does not rescue from unexpected api errors' do  
      expect(api).to receive(:resource).with("variable:tempfile_b") { raise "Custom error" }
      expect { subject.check(api) }.to raise_error "Custom error"
    end

    it "returns Hash consisting of original keys and following statuses: :literal, :available, :unavailable" do
      expect(api).to receive(:resource).with("variable:tempfile_b").and_return(permitted) 
      expect(api).to receive(:resource).with("variable:conjurvar_c").and_return(restricted) 
      expect(api).to receive(:resource).with("variable:tempfile_d").and_return(restricted) 
      expect(api).to receive(:resource).with("variable:conjurvar_e").and_return(permitted) 
      
      result = expect(subject.check(api)).to eq({ "a" => :literal, 
                                              "b" => :available, 
                                              "c" => :unavailable, 
                                              "d" => :unavailable, 
                                              "e" => :available 
                                            })
    end
  end
    
end
