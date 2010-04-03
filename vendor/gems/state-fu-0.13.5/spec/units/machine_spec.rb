require File.expand_path("#{File.dirname(__FILE__)}/../helper")

## See state_and_event_common_spec.rb for behaviour shared between
## StateFu::State and StateFu::Event
##

describe StateFu::Machine do
  include MySpecHelper

  before do
  end

  describe "class methods" do
    before do

    end

    describe "Machine.for_class" do
      describe "when there's no machine defined for the class" do
        before do
          reset!
          make_pristine_class 'Klass'
        end

        it "should create a new machine and bind! it" do
          @machine = Object.new
          @machine.should_receive(:bind!).with(Klass, :moose, {})
          StateFu::Machine.should_receive(:new).and_return @machine
          StateFu::Machine.for_class Klass, :moose
        end

        it "should apply the block (via lathe) if one is given" do
          @m = StateFu::Machine.for_class Klass, :snoo do
            state :porpoise
          end
        end
      end

    end
  end

  describe "attributes" do
  end

  describe "instance methods" do
    before do
      reset!
      make_pristine_class 'Klass'
      @m = StateFu::Machine.new
    end

    describe "helper" do
      it "should add its arguments to the @@helpers array" do
        module Foo; FOO = :foo; end
        module Bar; BAR = :bar; end
        @m.helper Foo, Bar
        @m.helpers.should == [Foo, Bar]
      end

    end

    describe ".initialize" do
      it "should apply options to the machine" do
        @m = StateFu::Machine.new( :colour => "blue")
        @m.options.should == {:colour => "blue" }
      end
    end

    describe ".apply!" do

    end

    describe ".bind!" do
      it "should call StateFu::Machine.bind! with itself and its arguments" do
        field_name = :my_field_name
        StateFu::Machine.should_receive(:bind!).with @m, Klass, :newname, field_name 
        @m.bind!( Klass, :newname, field_name )
      end

      it "should generate a field name if none is given" do
        klass      = Klass
        name       = :StinkJuice
        field_name = 'stink_juice_field'
        @m.bind!( Klass, name )
        Klass.state_fu_options[name][:field_name].should == 'stink_juice_field'
      end
    end

    describe ".initial_state=" do

      it "should set @initial_state given a String, Symbol or State for an existing state" do
        state = StateFu::State.new( @m, :wizzle )
        @m.states << state
        @m.initial_state = state
        @m.initial_state.should == state
      end

      it "should create the state if it doesnt exist" do
        @m.initial_state = :snoo
        @m.initial_state.should be_kind_of( StateFu::State )
        @m.initial_state.name.should == :snoo
        @m.states.should include( @m.initial_state )
      end

      it "should raise an ArgumentError given a number or an Array" do
        lambda do @m.initial_state = 6
        end.should raise_error( ArgumentError )

        lambda do @m.initial_state = [:ping]
        end.should raise_error( ArgumentError )
      end

    end

    describe ".initial_state" do
      it "should return nil if there are no states and initial_state= has not been called" do
        @m.states.should == []
        @m.initial_state.should == nil
      end

      it "should return the first state if one exists" do
        @m.should_receive(:states).and_return [:a, :b, :c] 
        @m.initial_state.should == :a
      end

    end

    describe ".states" do
      it "should return an array extended with StateFu::StateArray" do
        @m.states.should be_kind_of( Array )
        @m.states.extended_by.should include( StateFu::StateArray )
      end
    end

    describe ".state_names" do
      it "should return a list of symbols of state names" do
        @m.states << StateFu::State.new( @m, :a )
        @m.states << StateFu::State.new( @m, :b )
        @m.state_names.should == [:a, :b ]
      end
    end

    describe ".events" do
      it "should return an array extended with StateFu::EventArray" do
        @m.events.should be_kind_of( Array )
        @m.events.extended_by.should include( StateFu::EventArray )
      end
    end

    describe ".event_names" do
      it "should return a list of symbols of event names" do
        @m.events << StateFu::Event.new( @m, :a )
        @m.events << StateFu::Event.new( @m, :b )
        @m.event_names.should == [:a, :b ]
      end
    end

    describe ".find_or_create_states_by_name" do
      describe "given an array of symbols" do
        it "should return the states named by the symbols if they exist" do
          a = StateFu::State.new( @m, :a )
          b = StateFu::State.new( @m, :b )
          @m.states << a
          @m.states << b
          @m.find_or_create_states_by_name( :a, :b ).should == [a, b]
          @m.find_or_create_states_by_name( [:a, :b] ).should == [a, b]
        end

        it "should return the states named by the symbols and create them if they don't exist" do
          @m.states.should == []
          res = @m.find_or_create_states_by_name( :a, :b )
          res.should be_kind_of( Array )
          res.length.should == 2
          res.all? { |e| e.class == StateFu::State  }.should be_true
          res.map(&:name).should == [ :a, :b ]
          @m.find_or_create_states_by_name( :a, :b ).should == res
        end
      end # arr symbols

      describe "given an array of states" do
        it "should return the states if they're in the machine's states array" do
          a = StateFu::State.new( @m, :a )
          b = StateFu::State.new( @m, :b )
          @m.states << a
          @m.states << b
          @m.find_or_create_states_by_name( a, b ).should == [a, b]
          @m.find_or_create_states_by_name( [a, b] ).should == [a, b]
          @m.find_or_create_states_by_name( [[a, b]] ).should == [a, b]
        end

        it "should add the states to the machine's states array if they're absent" do
          a = StateFu::State.new( @m, :a )
          b = StateFu::State.new( @m, :b )
          @m.find_or_create_states_by_name( a, b ).should == [a, b]
          @m.find_or_create_states_by_name( [a, b] ).should == [a, b]
          @m.find_or_create_states_by_name( [[a, b]] ).should == [a, b]
        end
      end # arr states
    end # find_or_create_states_by_name

    describe "requirement_messages" do
      it "should be a hash" do
        @m.should respond_to(:requirement_messages)
        @m.requirement_messages.should be_kind_of( Hash )
      end

      it "should be empty by default" do
        @m.requirement_messages.should be_empty
      end

    end # requirement_messages

    describe "named_procs" do
      it "should be a hash" do
        @m.should respond_to(:named_procs)
        @m.named_procs.should be_kind_of( Hash )
      end

      it "should be empty by default" do
        @m.named_procs.should be_empty
      end

    end # named_procs

    describe "#serializable?" do
      it "should be true if the machine has no procs / lambdas" do
        StateFu::Machine.new.should be_serializable
      end

      it "should be false if it has a named_proc" do
        other_machine = StateFu::Machine.new do
          named_proc(:do_stuff) { puts "I has a proc" }
        end
        other_machine.serializable?.should == false
      end

      it "should be false if any states / events are not seralizable" do
        other_machine = StateFu::Machine.new do
          state :red
        end
        other_machine.states.first.should_receive(:serializable?).and_return(false)
        other_machine.serializable?.should == false      
      end
    end

  end # instance methods
end
