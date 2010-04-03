require File.expand_path("#{File.dirname(__FILE__)}/../helper")

##
##
##

describe "Common features / functionality for StateFu::State & StateFu::Event" do

  include MySpecHelper
  Sprocket = StateFu::Sprocket
  before do
    @machine = StateFu::Machine.new
  end

  describe "calling Sprocket.new" do
    it "should create a new Sprocket given valid args" do
      sprocket = Sprocket.new(@machine, :flux, { :meta => :doodle })
      sprocket.should be_kind_of( Sprocket )
      sprocket.name.should == :flux
      sprocket.options[:meta].should == :doodle
      sprocket.machine.should == @machine
    end
  end

  describe "instance methods" do
    before do
      @sprocket = Sprocket.new(@machine, :flux, {:meta => "wibble"})
    end

    describe ".apply!" do

      it "should yield itself if the block's arity is 1" do
        yielded = false
        @sprocket.apply!{ |s| yielded = s  }
        yielded.should == @sprocket
      end

      it "should instance_eval the block if its arity is 0/-1" do
        yielded = false
        @sprocket.apply!{ yielded = self }
        yielded.should == @sprocket
      end
      
      it "should merge any options passed into .options" do
        opts    = @sprocket.options
        newopts =  { :size => "huge", :colour => "orange" }
        @sprocket.apply!( newopts )
        @sprocket.options.should == opts.merge(newopts)
      end

      it "should instance_eval the block if one is passed" do
        ref = nil
        @sprocket.apply!(){ ref = self }
        ref.should == @sprocket
      end

      it "should return itself" do
        @sprocket.apply!.should == @sprocket
      end
    end

    describe "to_sym" do
      it "should return its name" do
        @sprocket.to_sym.should == @sprocket.name
      end
    end

    describe "#serializable?" do
      it "should be true if hooks contains no procs and options are empty" do
        @sprocket.hooks.values.flatten.map(&:class).include?(Proc).should == false
        @sprocket.options = {}
        @sprocket.serializable?.should == true
      end
      
      it "should be false if hooks contains any procs" do
        pending 
        # ...
        @sprocket.serializable?.should == false
      end
      
      it "should be false if options contains anything which cannot be turned into yaml" do
        @sprocket.serializable?.should == true
        @sprocket.options[:whut] = Class
        lambda do
          @sprocket.options.to_yaml
        end.should raise_error
        @sprocket.serializable?.should == false   
      end
    end
    
  end
end
