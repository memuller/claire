require File.expand_path("#{File.dirname(__FILE__)}/../spec_helper")

describe "extending bindings and transitions with Lathe#helper" do

  include MySpecHelper

  before(:each) do
    reset!
    make_pristine_class('Klass')
    Klass.class_eval do
      attr_accessor :ok
    end

    @machine = Klass.machine do
      chain "a -a2b-> b -b2c-> c"
      events.each do |e|
        e.requires :ok
      end
    end

    @obj = Klass.new
    @binding       = @obj.state_fu
    @transition    = @obj.state_fu.transition(:a2b)
  end # before

  #
  #

  describe StateFu::Transition  do
    describe "equality" do

      it "should == the current_state" do
        @transition.should == @transition.current_state
      end

      it "should != any other state" do
        @transition.should_not == @transition.target
      end

      it "should == the current_state_name" do
        @transition.should == @transition.current_state
      end

      it "should != any other State's name" do
        @transition.should_not == @transition.target.name
      end

      describe "with an unaccepted transition" do
        before do
          # stub(@transition).accepted? { false }
        end

        it "should != true" do
          @transition.should_not == true
        end

        it "should == false" do
          @transition.should == false
        end

        it "should not === true" do
          @transition.should_not === true
        end

        it "should === false" do
          @transition.should === false
        end
        
        it "should not be nil?" do
          @transition.nil?.should be_false
        end
      end


      describe "with an accepted transition" do
        before do
          @obj.ok = true
          @transition.fire!
          @transition.should be_accepted
        end
        it "should == true" do
          @transition.should == true
        end

        it "should not == false" do
          @transition.should_not == false
        end

        it "should === true" do
          @transition.should === true
        end

        it "should not === false" do
          @transition.should_not === false
        end

      end
    end

  end
end
