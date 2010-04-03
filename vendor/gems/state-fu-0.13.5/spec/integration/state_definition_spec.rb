require File.expand_path("#{File.dirname(__FILE__)}/../helper")

##
##
##

describe "Adding states to a Machine" do

  include MySpecHelper

  before(:each) do
    make_pristine_class 'Klass'
    @k = Klass.new()
  end

  it "should allow me to call machine() { state(:egg) }" do
    lambda {Klass.state_fu_machine(){ state :egg } }.should_not raise_error()
  end

  describe "having called machine() { state(:egg) }" do

    before(:each) do
      Klass.state_fu_machine(){ state :egg }
    end

    it "should return [:egg] given machine.state_names" do
      Klass.state_fu_machine.should respond_to(:state_names)
      Klass.state_fu_machine.state_names.should == [:egg]
    end

    it "should return [<StateFu::State @name=:egg>] given machine.states" do
      Klass.state_fu_machine.should respond_to(:states)
      Klass.state_fu_machine.states.length.should == 1
      Klass.state_fu_machine.states.first.should be_kind_of( StateFu::State )
      Klass.state_fu_machine.states.first.name.should == :egg
    end

    it "should return :egg given machine.states.first.name" do
      Klass.state_fu_machine.should respond_to(:states)
      Klass.state_fu_machine.states.length.should == 1
      Klass.state_fu_machine.states.first.should respond_to(:name)
      Klass.state_fu_machine.states.first.name.should == :egg
    end

    it "should return a <StateFu::State @name=:egg> given machine.states[:egg]" do
      Klass.state_fu_machine.should respond_to(:states)
      result = Klass.state_fu_machine.states[:egg]
      result.should_not be_nil
      result.should be_kind_of( StateFu::State )
      result.name.should == :egg
    end


    it "should allow me to call machine(){ state(:chick) }" do
      lambda {Klass.state_fu_machine(){ state :chick } }.should_not raise_error()
    end

    describe "having called machine() { state(:chick) }" do
      before do
        Klass.state_fu_machine() { state :chick }
      end

      it "should return [:egg] given machine.state_names" do
        Klass.state_fu_machine.should respond_to(:state_names)
        Klass.state_fu_machine.state_names.should == [:egg, :chick]
      end

      it "should return a <StateFu::State @name=:chick> given machine.states[:egg]" do
        Klass.state_fu_machine.should respond_to(:states)
        result = Klass.state_fu_machine.states[:chick]
        result.should_not be_nil
        result.should be_kind_of( StateFu::State )
        result.name.should == :chick
      end

    end

    describe "calling machine() { state(:bird) {|s| .. } }" do

      it "should yield the state to the block as |s|" do
        state = nil
        Klass.state_fu_machine() do
          state(:bird) do |s|
            state = s
          end
        end
        state.should be_kind_of( StateFu::State )
        state.name.should == :bird
      end

    end

    describe "calling machine() { state(:bird) {  ...  } }" do

      it "should instance_eval the block as a StateFu::Lathe" do
        lathe = nil
        Klass.state_fu_machine() do
          state(:bird) do
            lathe = self
          end
        end
        lathe.should be_kind_of(StateFu::Lathe)
        lathe.state_or_event.should be_kind_of(StateFu::State)
        lathe.state_or_event.name.should == :bird
      end

    end

    describe "calling state(:bird) consecutive times" do

      it "should yield the same state each time" do
        Klass.state_fu_machine() { state :bird }
        bird_1 = Klass.state_fu_machine.states[:bird]
        Klass.state_fu_machine() { state :bird }
        bird_2 = Klass.state_fu_machine.states[:bird]
        bird_1.should == bird_2
      end

    end
  end

  describe "calling machine() { states(:egg, :chick, :bird, :poultry => true) }" do

    it "should create 3 states" do
      Klass.state_fu_machine().should be_empty
      Klass.state_fu_machine() { states(:egg, :chick, :bird, :poultry => true) }
      Klass.state_fu_machine().state_names().should == [:egg, :chick, :bird]
      Klass.state_fu_machine().states.length.should == 3
      Klass.state_fu_machine().states.map(&:name).should == [:egg, :chick, :bird]
      Klass.state_fu_machine().states().each do |s|
        s.options[:poultry].should be_true
        s.should be_kind_of(StateFu::State)
      end
    end

    describe "merging options" do
      before do
        make_pristine_class('Klass')          
      end     
      it "should merge options when states are mentioned more than once" do
        # reset! 
        machine = Klass.state_fu_machine
        machine.states.length.should == 0
        Klass.state_fu_machine() { states(:egg, :chick, :bird, :poultry => true) }
        machine = Klass.state_fu_machine
        machine.states.length.should == 3

        # make sure they're the same states
        states_1 = machine.states
        Klass.state_fu_machine(){ states( :egg, :chick, :bird, :covering => 'feathers')}
        states_1.should == machine.states

        # ensure options were merged
        machine.states().each do |s|
          s.options[:poultry].should be_true
          s.options[:covering].should == 'feathers'
          s.should be_kind_of(StateFu::State)
        end
      end
    end
  end
end

