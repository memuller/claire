require File.expand_path("#{File.dirname(__FILE__)}/../helper")

describe StateFu::MethodFactory do
  include MySpecHelper

  # TODO - move to eg method_factory integration spec
  describe "event_methods" do

    before do
      make_pristine_class('Klass')
    end

    describe "defined on the stateful instance / object before state_fu has been called" do

      before do
          @machine = Klass.state_fu_machine do
            event( :simple_event,
                   :from => { [:a, :b] => :targ } )
            state( :a ) { cycle }
          end # machine
          @obj     = Klass.new
      end

      describe "when there is a method_missing already defined for the class" do
        before do
          reset!
          make_pristine_class('Klass')
          Klass.class_eval do
            def method_missing method_name, *args
              callme
            end 
          end
          Klass.state_fu_machine(){}
        end 
        it "should call the original method_missing on an unexpected method call" do 
          @k = Klass.new
          @k.should_receive(:callme)
          @k.whut?
        end
      end

      describe "event creation methods" do
        it "should call method_missing" do
          pending "RSpec mocking makes this tricky ..."
          @obj.should_receive(:method_missing).with(:simple_event!)
          mock( @obj ).method_missing( :simple_event! )
          @obj.simple_event!
        end

        it "should call state_fu!" do
          pending "RSpec mocking makes this tricky ..."
          mock.proxy( StateFu::Binding ).new( Klass.state_fu_machine, @obj, StateFu::DEFAULT )
          @obj
          @obj.private_methods.map(&:to_sym).should include(:state_fu_field)
          #@obj.should respond_to StateFu::DEFAULT_FIELD
          @obj.state_fu.machine.events.should_not be_empty
          @obj.simple_event!

          # @obj.should_have_received( :state_fu! )
        end

        it "should not raise a NoMethodError" do
          lambda { @obj.simple_event! }.should_not raise_error( NoMethodError )
        end

        it "should call binding.fire!( :simple_event ... ) with any specified args" do
          pending "RSpec mocking makes this tricky ..."
          
          mock.instance_of( StateFu::Binding ).fire_transition!( is_a(StateFu::Event), is_a(StateFu::State), :aa, :bb, {:cc => "dd"} )
          t = @obj.simple_event!( :aa, :bb, :cc => "dd" )
        end

        it "should fire the transition" do
          @obj.send(:state_fu_field).should == nil
          t = @obj.simple_event!
          t.should be_accepted
          @obj.send(:state_fu_field).should == 'targ'
        end
      end
    end


    describe "defined on the binding" do
      describe "when the event is simple (has only one possible target)" do
        before do
          @machine = Klass.state_fu_machine do
            event( :simple_event,
                   :from => { [:a, :b] => :targ } )
          end # machine
          @obj     = Klass.new
          @binding = @obj.state_fu
        end # before

        it "should be simple?" do
          e = @machine.events[:simple_event]
          e.origins.length.should == 2
          e.targets.length.should == 1
          e.should be_simple
        end

        describe "method which returns an unfired transition" do
          it "should have the same name as the event" do
            @binding.should respond_to(:simple_event)
          end

          it "should return a new transition if called without any arguments" do
            t = @binding.simple_event()
            t.should be_kind_of( StateFu::Transition )
            t.target.should == @machine.states[:targ]
            t.event.should == @machine.events[:simple_event]
            t.should_not be_fired
          end

          it "should add any arguments / options it is called with to the transition" do
            t = @binding.simple_event :a, :b, :c, {'d' => 'e'}
            #t.should be_kind_of( StateFu::Transition )
            #t.target.should  == @machine.states[:targ]
            #t.event.should   == @machine.events[:simple_event]
            t.args.should    == [:a,:b,:c,{'d' => 'e'}]
            t.options.should == {:d => 'e'}
          end
        end # transition builder

        describe "method which tests if the event is can_transition?" do
          it "should have the name of the event suffixed with ?" do
            @binding.should respond_to(:can_simple_event?)
          end

          it "should be true when the binding says it\'s can_transition?" do
            @binding.can_transition?( :simple_event ).should == true
            @binding.can_simple_event?.should == true
          end

          it "should be false when the binding says it\'s not can_transition?" do
            @binding.should_receive(:can_transition?).with(@machine.events[:simple_event], @machine.states[:targ]).and_return false
            @binding.can_simple_event?.should == false
          end
        end # can_transition?

        describe "bang (!) method which creates, fires and returns a transition" do
          it "should have the name of the event suffixed with a bang (!)" do
            @binding.should respond_to(:simple_event!)
          end

          it "should return a fired transition" do
            t = @binding.simple_event!
            t.should be_kind_of( StateFu::Transition )
            t.should be_fired
          end

          it "should pass any arguments to the transition as args / options" do
            t = @binding.simple_event!( :a, :b, {'c' => :d } )
            t.should be_kind_of( StateFu::Transition )
            t.args.should    == [:a, :b, {'c' => :d} ]
            t.options.should == { :c => :d }
          end
        end # bang!
      end # simple

      describe "when the event is complex (has more than one possible target)" do
        before do
          @machine = Klass.state_fu_machine do
            state :orphan
            event( :complex_event,
                   :from => :home,
                   :to => [ :x, :y, :z ] )
            initial_state :home
          end # machine
          @obj     = Klass.new
          @binding = @obj.state_fu
        end # before

        it "should not be simple?" do
          e = @machine.events[:complex_event]
          e.origins.length.should == 1
          e.targets.length.should == 3
          e.should_not be_simple
        end

        describe "method which returns an unfired transition" do
          it "should have the same name as the event" do
            @binding.should respond_to(:complex_event)
          end

          it "should raise an error if called without any arguments" do
            lambda { @binding.complex_event() }.should raise_error( ArgumentError )
          end

          it "should raise an ArgumentError if called with a nonexistent target state" do
            lambda { @binding.complex_event(:nonexistent) }.should raise_error( StateFu::UnknownTarget )
          end

          it "should raise an IllegalTransition if called with an invalid target state" do
            lambda { @binding.complex_event(:orphan)      }.should raise_error( StateFu::IllegalTransition )
          end

          it "should return a transition to the specified state if supplied a valid state" do
            t = @binding.complex_event( :x )
            t.should be_kind_of( StateFu::Transition )
            t.target.name.should == :x
          end

          it "should add any arguments / options it is called with to the transition" do
            t = @binding.complex_event(:x,
                                       :a, :b, :c, {'d' => 'e'})
            t.should be_kind_of( StateFu::Transition )
            t.args.should == [:a,:b,:c,{'d' =>'e'}]
            t.options.should == {:d => 'e'}
          end
        end # transition builder

        describe "method which tests if the event is can_transition?" do
          it "should have the name of the event suffixed with ?" do
            @binding.should respond_to(:can_complex_event?)
          end

          it "should require a valid state name" do
            lambda { @binding.can_complex_event?(:nonexistent) }.should raise_error( StateFu::UnknownTarget )
            lambda { @binding.can_complex_event?(:orphan) }.should_not  raise_error()
            @binding.can_complex_event?(:orphan).should == false
            lambda { @binding.can_complex_event?(:x) }.should_not       raise_error
          end

          it "should be true when the binding says the event is can_transition? " do
            @binding.can_transition?( :complex_event, :x ).should == true
            @binding.can_complex_event?(:x).should == true
          end
        end # can_transition?

        describe "bang (!) method which creates, fires and returns a transition" do
          it "should have the name of the event suffixed with a bang (!)" do
            @binding.should respond_to(:complex_event!)
          end

          it "should require a valid state name" do
            lambda { @binding.complex_event!(:nonexistent) }.should raise_error( StateFu::UnknownTarget )
            lambda { @binding.complex_event!(:orphan) }.should      raise_error( StateFu::IllegalTransition )
            lambda { @binding.complex_event!(:x) }.should_not       raise_error
          end

          it "should return a fired transition given a valid state name" do
            t = @binding.complex_event!( :x )
            t.should be_kind_of( StateFu::Transition )
            t.target.should == @machine.states[:x]
            t.should be_fired
          end

          it "should pass any arguments to the transition as args / options" do
            t = @binding.complex_event!( :x,
                                         :a, :b, {'c' => :d } )
            t.should be_kind_of( StateFu::Transition )
            t.target.should  == @machine.states[:x]
            t.args.should    == [:a, :b,{'c' =>:d} ]
            t.options.should == { :c => :d }
          end
        end # bang!
      end # complex_event

      # TODO move these to binding spec
      describe "cycle and next_state methods" do
        describe "when there is a valid transition available for cycle and next_state" do
          before do
            @machine = Klass.state_fu_machine do
              initial_state :groundhog_day

              state(:groundhog_day) do
                cycle
              end

              event(:end_movie, :from => :groundhog_day, :to => :happy_ending)
            end # machine
            @obj     = Klass.new
            @binding = @obj.state_fu
          end # before

          describe "cycle methods:" do
            describe "cycle" do
              it "should return a transition for the cyclical event" do
                t = @binding.cycle
                t.should be_kind_of( StateFu::Transition )
                t.origin.name.should == :groundhog_day
                t.target.name.should == :groundhog_day
                t.should_not be_fired
              end
            end

            describe "cycle?" do
            end

            describe "cycle!" do
            end
          end # cycle

          describe "next_state methods:" do
            describe "next_state" do
            end

            describe "next_state?" do
            end

            describe "next_state!" do
            end
          end # next_state
        end # with valid transitions

        describe "when the machine is empty" do
          before do
            @machine = Klass.state_fu_machine() {}
            @obj     = Klass.new
            @binding = @obj.state_fu
          end

          describe "current_state" do
            it "should be nil" do
              @binding.current_state.should == nil
            end
          end
          describe "cycle methods:" do
            describe "cycle" do
              it "should return nil" do
                @binding.cycle.should == nil
              end
            end

            describe "cycle?" do
              it "should return nil" do
                @binding.cycle?.should == nil
              end
            end

            describe "cycle!" do
              it "should raise_error( TransitionNotFound )" do
                lambda { @binding.cycle!.should == nil }.should raise_error( StateFu::TransitionNotFound )
              end
            end
          end # cycle

          describe "next_state methods:" do
            describe "next_state" do
              it "should return nil" do
                @binding.next_state.should == nil
              end
            end

            describe "next_state?" do
              it "should return nil" do
                pending
                @binding.next_state?.should == nil
              end
            end

            describe "next_state!" do
              it "should raise_error( IllegalTransition )" do
                lambda { @binding.next_state! }.should raise_error( StateFu::TransitionNotFound )
              end
            end
          end # next_state

        end # empty machine

        describe "when there is more than one candidate event / state" do
        end # too many candidates

      end   # cycle & next_state
    end     # defined on binding

    describe "methods defined on the object" do
    end

  end       # event methods
end
