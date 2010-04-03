require File.expand_path("#{File.dirname(__FILE__)}/../helper")

describe StateFu::Binding do
  include MySpecHelper

  describe "instance methods" do
  end

  #
  # class methods
  #

  describe "class methods" do
  end


  #
  #
  #

  before do
    reset!
    make_pristine_class('Klass')
    Klass.state_fu_machine(){}
    @obj = Klass.new()
  end

  describe "constructor" do
    before do
      Klass.should_receive(:state_fu_options).at_most(3).times.and_return({
        :example => {:field_name => :example_field}         
      })
    end

    it "should create a new Binding given valid arguments" do
      b = StateFu::Binding.new( Klass.state_fu_machine, @obj, :example )
      b.should be_kind_of( StateFu::Binding )
      b.object.should      == @obj
      b.machine.should     == Klass.state_fu_machine
      b.method_name.should == :example
    end

    it "should add any options supplied to the binding" do
      b = StateFu::Binding.new( Klass.state_fu_machine, @obj, :example,
                                :colour => :red,
                                :style  => [:robust, :fruity] )
      b.options.should == { :colour => :red, :style  => [:robust, :fruity] }
    end

    describe "persister initialization" do
      before do
        @p = Object.new
        class << @p
          attr_accessor :field_name
        end
        @p.field_name
      end

      describe "when StateFu::Persistence.active_record_column? is true" do
        
        before do
          StateFu::Persistence.should_receive(:active_record_column?).with(Klass, :example_field).and_return true
          Klass.should_receive(:before_validation_on_create).with(:state_fu!)
        end
        
        it "should get an ActiveRecord persister" do
          StateFu::Persistence::ActiveRecord.should_receive(:new).with(anything, :example_field).and_return(@p)
          b = StateFu::Binding.new( Klass.state_fu_machine, @obj, :example )
          b.persister.should == @p
        end
      end

      describe "when StateFu::Persistence.active_record_column? is false" do
        before do
          StateFu::Persistence.should_receive(:active_record_column?).with(Klass, :example_field).and_return false
        end
        it "should get an Attribute persister" do
          StateFu::Persistence::Attribute.should_receive(:new).with(anything, :example_field).and_return @p
          b = StateFu::Binding.new( Klass.state_fu_machine, @obj, :example )
          b.persister.should == @p
        end
      end
    end
  end

  describe "initialization via @obj.state_fu()" do
    it "should create a new StateFu::Binding with default method-name & field_name" do
      b = @obj.state_fu()
      b.should be_kind_of( StateFu::Binding )
      b.machine.should      == Klass.state_fu_machine
      b.object.should       == @obj
      b.method_name.should       == StateFu::DEFAULT
      b.field_name.to_sym.should == StateFu::DEFAULT_FIELD
    end
  end

  describe "a binding for the default machine with two states and an event" do
    before do
      reset!
      make_pristine_class('Klass')
      Klass.state_fu_machine do
        state :new do
          event :age, :to => :old
        end
        state :old
      end
      @machine   = Klass.state_fu_machine()
      @object    = Klass.new()
      @binding   = @object.state_fu()
    end

    describe "==" do
      it "should be == :new" do
        @binding.should == :new
      end
    end

    describe ".state and .initial_state" do
      it "should default to machine.initial_state when no initial_state is explicitly defined" do
        @machine.initial_state.name.should == :new
        @binding.current_state.should == @machine.initial_state
      end

      it "should default to the machine's initial_state if one is set" do
        @machine.initial_state = :fetus
        @machine.initial_state.name.should == :fetus
        obj = Klass.new
        obj.state_fu.current_state.should == @machine.initial_state
      end
    end

  end

  describe "Instance methods" do
    before do
    end
    describe "can_transition?" do
      before do
        reset!
        make_pristine_class("Klass")
        Klass.class_eval do
          def tissue?(*args); "o_O"; end
        end
        @machine = Klass.state_fu_machine do
          state :snoo do
            event :fire, :to => :wizz do
              requires :tissue?
            end
          end
          state :wizz do
            event :not_fireable, :to => :pong
          end
        end
        @obj = Klass.new
      end

      describe "when called with arguments which would return a valid transition from .transition()" do
        it "should return true" do
          @obj.state_fu.can_transition?(:fire).should == true
        end
      end

      describe "when called with arguments which would raise an IllegalTransition from .transition()" do
        it "should return nil" do
          @obj.state_fu.name.should == :snoo
          lambda { @obj.state_fu.can_transition?(:not_fire) }.should_not raise_error( StateFu::IllegalTransition )
          @obj.state_fu.can_transition?(:not_fire).should == nil
        end
      end

      describe "when called with additional arguments after the destination event/state" do

        # This would make very little sense to someone trying to understand how to use the library.
        # figure out how to spec it properly.
        it "should pass the arguments to any requirements to determine transition availability" do
          pending
          t = nil
          mock(@obj).tissue?(anything) do
            # current_transition.should be_kind_of(StateFu::Transition)
            t << current_transition
          end #{|tr| tr.args.should == [:a,:b] }
          @obj.state_fu.can_fire?(:a, :b)
        end
      end

    end

  end
end
