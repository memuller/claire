require File.expand_path("#{File.dirname(__FILE__)}/../helper")

# TODO - refactor me into manageable chunks

describe StateFu::Transition do
  include MySpecHelper
  before do
    reset!
    make_pristine_class("Klass")
  end

  describe "transition args / options" do
    before do
      make_pristine_class('Alphabet') do
        machine do
          connect_states :a, :b
        end
      end
      @abc = Alphabet.new
      evt  = Alphabet.machine.events[:a_to_b]
      tgt  = Alphabet.machine.states[:b]
      @t   = StateFu::Transition.new(@abc.stfu, evt, tgt,
                                      :a, :b, 'c' => 'cat')
    end

    it "should behave like this" do
      @t.args.should    == [:a, :b, {'c' => 'cat'}]
      @t.options.should == {:c => 'cat'} 

      @t.apply!({'d' => :e})
      @t.options.should == {:c => 'cat', :d =>  :e} 
      
      @t.args.should    == [:a, :b, {'c' => 'cat'}]
      
      @t.args = [:A, :B]
      @t.args.should    == [:A, :B]
      @t.options.should == {:c => 'cat', :d => :e} 
      
      @t.args = [:X, :Y, {:scale => :metric }]
      
      @t.options.should == { :c => 'cat', :d => :e , :scale => :metric }
      @t.args.options.should == @t.options
    end
  end

  #
  #
  #

  describe "A simple machine with 2 states and a single event" do
    before do
      @machine = Klass.state_fu_machine do
        state :src do
          event :transfer, :to => :dest
        end
      end
      @origin = @machine.states[:src]
      @target = @machine.states[:dest]
      @event  = @machine.events.first
      @obj    = Klass.new
    end

    it "should have two states named :src and :dest" do
      @machine.states.length.should == 2
      @machine.states.should        == [@origin, @target]
      @origin.name.should           == :src
      @target.name.should           == :dest
      @machine.state_names.should   == [:src, :dest]
    end

    it "should have one event :transfer, from :src to :dest" do
      @machine.events.length.should == 1
      @event.origin.should          == @origin
      @event.target.should          == @target
    end

    describe "instance methods on a transition" do
      before do
        @t = @obj.state_fu.transition( :transfer )
      end

      describe "the transition before firing" do
        it "should not be fired" do
          @t.should_not be_fired
        end

        it "should not be halted" do
          @t.should_not be_halted
        end

        it "should not be accepted" do
          @t.should_not be_accepted
        end

        it "should have a current_state of the origin state" do
          @t.current_state.should == @origin
        end

        it "should have a current_hook of nil" do
          @t.current_hook.should == nil
        end
      end # transition before fire!

      describe "calling fire! on a transition with no conditions or hooks" do
        it "should change the state of the binding" do
          @obj.state_fu.state.should == @origin
          @t.fire!
          @obj.state_fu.state.should == @target
        end

        it "should have an empty set of hooks" do
          @t.hooks.map(&:last).flatten.should == []
        end

        it "should change the field when persistence is via an attribute" do
          @obj.state_fu.persister.should be_kind_of( StateFu::Persistence::Attribute )
          @obj.state_fu.persister.field_name.to_s.should == StateFu::DEFAULT_FIELD.to_s
          @obj.send( :state_fu_field ).should == "src"
          @t.fire!
          @obj.send( :state_fu_field ).should == "dest"
        end
      end # transition.fire!

      describe "the transition after firing is complete" do
        before do
          @t.fire!()
        end

        it "should be fired" do
          @t.should be_fired
        end

        it "should not be halted" do
          @t.should_not be_halted
        end

        it "should be accepted" do
          @t.should be_accepted
        end

        it "should have a current_state of the target state" do
          @t.current_state.should == @target
        end

        it "should have a current_hook && current_hook_slot of nil" do
          @t.current_hook.should == nil
          @t.current_hook_slot.should == nil
        end
      end # transition after fire
    end # transition instance methods

    # binding instance methods
    # TODO move these to binding spec
    describe "instance methods on the binding" do
      describe "constructing a new transition with state_fu.transition" do

        it "should raise an ArgumentError if a bad event name is given" do
          lambda do
            trans = @obj.state_fu.transition( :transfibrillate )
          end.should raise_error( ArgumentError )
        end

        it "should create a new transition given an event_name" do
          trans = @obj.state_fu.transition( :transfer )
          trans.should be_kind_of( StateFu::Transition )
          trans.binding.should == @obj.state_fu
          trans.object.should  == @obj
          trans.origin.should  == @origin
          trans.target.should  == @target
          trans.options.should == {}
          trans.errors.should  == []
          trans.args.should    == []
        end

        it "should create a new transition given a StateFu::Event" do
          e = @obj.state_fu.machine.events.first
          e.name.should == :transfer
          trans = @obj.state_fu.transition( e )
          trans.should be_kind_of( StateFu::Transition )
          trans.binding.should == @obj.state_fu
          trans.object.should  == @obj
          trans.origin.should  == @origin
          trans.target.should  == @target
          trans.options.should == {}
          trans.errors.should  == []
          trans.args.should    == []
        end

        it "should define any methods declared in a block given to .transition" do
          trans = @obj.state_fu.transition( :transfer ) do 
            def snoo
              return [self]
            end
          end
          trans.should be_kind_of( StateFu::Transition )
          trans.should respond_to(:snoo)
          trans.snoo.should == [trans]
          t2 = @obj.state_fu.transition( :transfer )
          t2.should_not respond_to( :snoo)
        end
      end # state_fu.transition

      describe "state_fu.events" do
        it "should be an array with the only event as its single element" do
          @obj.state_fu.events.should == [@event]
        end
      end

      describe "state_fu.fire!( :transfer )" do
        it "should change the state when called" do
          @obj.state_fu.should respond_to( :fire_transition! )
          @obj.state_fu.state.should == @origin
          @obj.state_fu.fire_transition!( :transfer )
          @obj.state_fu.state.should == @target
        end

        it "should return a transition object" do
          @obj.state_fu.fire_transition!( :transfer ).should be_kind_of( StateFu::Transition )
        end

      end # state_fu.fire!

      describe "calling cycle!()" do
        it "should raise a TransitionNotFound error" do
          lambda { @obj.state_fu.cycle!() }.should raise_error( StateFu::TransitionNotFound )
        end
      end # cycle!

      describe "calling next!()" do
        it "should change the state" do
          @obj.state_fu.state.should == @origin
          t = @obj.state_fu.transfer
          t.should be_valid
          @obj.state_fu.valid_transitions.length.should == 1
          @obj.state_fu.next!
          @obj.state_fu.state.should == @target
        end

        it "should return a transition" do
          trans = @obj.state_fu.next!()
          trans.should be_kind_of( StateFu::Transition )
        end

        it "should define any methods declared in a block given to .transition" do
          trans = @obj.state_fu.next_transition do
            def snoo
              return [self]
            end
          end
          trans.should be_kind_of( StateFu::Transition )
          # trans.should respond_to(:snoo)
          trans.snoo.should == [trans]
        end

        it "should raise an error when there is no next state" do
          Klass.state_fu_machine(:noop) {}
          lambda { @obj.noop.next! }.should raise_error( StateFu::TransitionNotFound )
        end
        it "should raise an error when there is more than one next state" do
          Klass.state_fu_machine(:toomany) { event( :go, :from => :one, :to => [:a,:b,:c] ) }
          lambda { @obj.toomany.next! }.should raise_error( StateFu::TransitionNotFound )
        end
      end # next!

      describe "passing args / options to the transition" do
        before do
          @args = [:a, :b, {:c => :d }]
        end

        describe "calling transition( :transfer, :a, :b, :c => :d )" do
          it "should set args and options on the transition" do
            t = @obj.state_fu.transition( :transfer, *@args )
            t.args.should    == [ :a, :b, {:c => :d} ]
            t.options.should == { :c => :d }
          end
        end

        describe "calling next!( :a, :b, :c => :d )" do
          it "should set args and options on the transition" do
            t = @obj.state_fu.next!( *@args )
            t.args.should    == [ :a, :b, {:c => :d}]
            t.options.should == { :c => :d }
          end
        end
      end # passing args / options
    end   # binding instance methods
  end     # simple machine w/ 2 states, 1 transition

  #
  #
  #

  describe "A simple machine with 1 state and an event cycling at the same state" do

    before do
      @machine = Klass.state_fu_machine do
        state :state_fuega do
          event :transfer, :to => :state_fuega
        end
      end
      @state = @machine.states[:state_fuega]
      @event = @machine.events.first
      @obj   = Klass.new
    end

    describe "state_fu instance methods" do
      describe "calling state_fu.cycle!()" do
        it "should not change the state" do
          @obj.state_fu.state.should == @state
          @obj.state_fu.cycle!
          @obj.state_fu.state.should == @state
        end

        it "should pass args / options to the transition" do
          t = @obj.state_fu.cycle!( nil, :a, :b , { :c => :d } )
          t.args.should    == [ :a, :b, { :c => :d } ]
          t.options.should == { :c => :d }
        end

        it "should not raise an error" do
          @obj.state_fu.cycle!
        end

        it "should return an accepted transition" do
          @obj.state_fu.state.should == @state
          t = @obj.state_fu.cycle!
          t.should be_kind_of( StateFu::Transition )
          t.should be_accepted
        end

      end  # state_fu.cycle!
    end    # state_fu instance methods
  end      # 1 state w/ cyclic event

  #
  #
  #

  describe "A simple machine with 3 states and an event to & from multiple states" do

    before do
      @machine = Klass.state_fu_machine do
        states :a, :b
        states :x, :y

        event( :go ) do
          from :a, :b
          to   :x, :y
        end

        initial_state :a
      end
      @a = @machine.states[:a]
      @b = @machine.states[:b]
      @x = @machine.states[:x]
      @y = @machine.states[:y]
      @event = @machine.events.first
      @obj   = Klass.new
    end

    it "should have an event from [:a, :b] to [:x, :y]" do
      @event.origins.should == [@a, @b]
      @event.targets.should == [@x, @y]
      @obj.state_fu.state.should == @a
    end

    describe "transition instance methods" do
    end

    describe "state_fu instance methods" do
      describe "state_fu.transition" do
        it "should raise StateFu::UnknownTarget unless a valid targets state is supplied or can be inferred" do
          lambda do
            @obj.state_fu.transition( :go )
          end.should raise_error( StateFu::UnknownTarget )

          lambda do
            @obj.state_fu.transition( [:go, nil] )
          end.should raise_error( StateFu::UnknownTarget )

          lambda do
            @obj.state_fu.transition( [:go, :awol] )
          end.should raise_error( StateFu::UnknownTarget )

          lambda do
            @obj.state_fu.transition( [:go, :x] )
            @obj.state_fu.transition( [:go, :y] )
          end.should_not raise_error( StateFu::UnknownTarget )
        end

        it "should return a transition with the specified destination" do
          t = @obj.state_fu.transition( [:go, :x] )
          t.should be_kind_of( StateFu::Transition )
          t.event.name.should == :go
          t.target.name.should == :x

          lambda do
            @obj.state_fu.transition( [:go, :y] )
          end.should_not raise_error( )
        end
      end  # state_fu.transition

      describe "state_fu.fire_transition!" do
        it "should raise an StateFu::UnknownTarget unless a valid targets state is supplied" do
          lambda do
            @obj.state_fu.fire_transition!( :go )
          end.should raise_error( StateFu::UnknownTarget )

          lambda do
            @obj.state_fu.fire_transition!( [ :go, :awol ] )
          end.should raise_error( StateFu::UnknownTarget )
        end
      end # state_fu.fire!

      describe "state_fu.next!" do
        it "should raise an StateFu::TransitionNotFound" do
          lambda do
            @obj.state_fu.next!
          end.should raise_error( StateFu::TransitionNotFound )
        end
      end # next!

      describe "state_fu.cycle!" do
        it "should raise StateFu::TransitionNotFound" do
          lambda do
            @obj.state_fu.cycle!
          end.should raise_error( StateFu::TransitionNotFound )
        end
      end # cycle!

    end    # state_fu instance methods
  end      # 1 state w/ cyclic event

  describe "A simple machine w/ 2 states, 1 event and named hooks " do
    before do
      Klass.class_eval do
        attr_reader :calls

        def called name
          (@calls ||= [])<< name
        end

        def before_go  ; called :before_go  end
        def after_go   ; called :after_go   end
        def execute_go ; called :execute_go end
        def entering_a ; called :entering_a end
        def accepted_a ; called :accepted_a end
        def exiting_a  ; called :exiting_a  end
        def entering_b ; called :entering_b end
        def accepted_b ; called :accepted_b end
        def exiting_b  ; called :exiting_b  end

      end

      @machine = Klass.state_fu_machine do

        state :a do
          on_exit( :exiting_a )
        end

        state :b do
          on_entry( :entering_b )
          accepted( :accepted_b )
        end

        event( :go ) do
          from :a, :to => :b

          before  :before_go
          execute :execute_go
          after   :after_go
        end

        initial_state :a
      end

      @a     = @machine.states[:a]
      @b     = @machine.states[:b]
      @event = @machine.events[:go]
      @obj   = Klass.new
    end # before

    describe "state :a" do
      it "should have a hook for on_exit" do
        @a.hooks[:exit].should == [ :exiting_a ]
      end
    end

    describe "state :b" do
      it "should have a hook for on_entry" do
        @b.hooks[:entry].should == [ :entering_b ]
      end
    end

    describe "event :go" do
      it "should have a hook for before" do
        @event.hooks[:before].should == [ :before_go ]
      end

      it "should have a hook for execute" do
        @event.hooks[:execute].should == [ :execute_go ]
      end

      it "should have a hook for after" do
        @event.hooks[:execute].should == [ :execute_go ]
      end
    end


    describe "a transition for the event" do

      it "should have all defined hooks in correct order of execution" do
        t = @obj.state_fu.transition( :go )
        hooks = t.hooks.map(&:last).flatten
        hooks.should be_kind_of( Array )
        hooks.should_not be_empty
        hooks.should == [ :before_go,
                          :exiting_a,
                          :execute_go,
                          :entering_b,
                          :after_go,
                          :accepted_b ]
      end
    end # a transition ..

    describe "fire! calling hooks" do
      before do
        @t = @obj.state_fu.transition(:go)
      end

      it "should change state between state:entering and event:after" do        
        @binding = @obj.state_fu
        @obj.should_receive(:entering_b).and_return do
          @obj.current_state.name.should == :a    
        end
        @obj.should_receive(:after_go).and_return do
          @obj.current_state.name.should == :b
        end
        @t.fire!
      end

      it "should call the method for each hook on @obj in order, with the transition" do
        hooks = [:before_go, :exiting_a, :execute_go, :entering_b, :after_go, :accepted_b]
        hooks.each do |hook|
          @obj.should_receive(hook).and_return do
            @obj.called hook
          end
        end
        @t.fire!()
        @obj.calls.should == hooks
      end

      describe "adding an anonymous hook for event.hooks[:execute]" do
        before do
          Klass.state_fu_machine do
            event( :go ) do
              execute do |ctx|
                called :execute_proc
              end
            end
          end
        end

        it "should be called at the correct point" do
          @event.hooks[:execute].length.should == 2
          @event.hooks[:execute].first.class.should == Symbol
          @event.hooks[:execute].last.class.should  == Proc
          @t.fire!()
          @obj.calls.should == [ :before_go,
                                 :exiting_a,
                                 :execute_go,
                                 :execute_proc,
                                 :entering_b,
                                 :after_go,
                                 :accepted_b ]
        end

        it "should be replace the previous proc for a slot if redefined" do
          called = @called # get us a ref for the closure
          Klass.state_fu_machine do
            event( :go ) do
              execute do |ctx|
                called(:updated)
              end
            end
          end
          @t.fire!
          @obj.calls.should == [:before_go, 
                                :exiting_a, 
                                :execute_go, 
                                :updated, 
                                :entering_b, 
                                :after_go, 
                                :accepted_b]
        end
      end   # anonymous hook

      describe "adding a named hook with a block" do
        describe "with arity of -1/0" do
          it "should call the block in the context of the transition" do
            Klass.state_fu_machine do
              event( :go ) do
                execute(:named_execute) do
                  called :execute_named_proc
                end
              end
            end
            @t.fire!()
            @obj.calls.should == [ :before_go,
                                   :exiting_a,
                                   :execute_go,
                                   :execute_named_proc,
                                   :entering_b,
                                   :after_go,
                                   :accepted_b ]
          end
        end # arity 0

        describe "with arity of 1" do
          it "should call the proc in the context of the object, passing the transition as the argument" do
            Klass.state_fu_machine do
              event( :go ) do
                execute(:named_execute) do |t|
                  called [:execute_named_proc, t]
                end
              end
            end
            @t.fire!()
            @obj.calls.should == [:before_go,
                                  :exiting_a,
                                  :execute_go,
                                  [:execute_named_proc, @t],
                                  :entering_b,
                                  :after_go,
                                  :accepted_b]
          end
        end # arity 1
      end   # named proc

      describe "halting the transition during the execute hook" do

        before do
          Klass.state_fu_machine do
            event( :go ) do
              execute do |transition|
                transition.halt!("stop")
              end
            end
          end
        end # before

        it "should prevent the transition from being accepted" do
          @obj.state_fu.state.name.should == :a
          @t.fire!()
          @obj.state_fu.state.name.should == :a
          @t.should be_kind_of( StateFu::Transition )
          @t.should be_halted
          @t.should_not be_accepted
          @obj.calls.flatten.should == [ :before_go,
                                         :exiting_a,
                                         :execute_go ]
        end

        it "should have current_hook_slot set to where it halted" do
          @obj.state_fu.state.name.should == :a
          @t.fire!()
          @t.current_hook_slot.should == [:event, :execute]
        end

        it "should have current_hook set to where it halted" do
          @obj.state_fu.state.name.should == :a
          @t.fire!()
          @t.current_hook.should be_kind_of( Proc )
        end

      end # halting from execute
    end   # fire! calling hooks

  end # machine w/ hooks

  describe "A binding for a machine with an event transition requirement" do
    before do
      @machine = Klass.state_fu_machine do
        event( :go, :from => :a, :to => :b ) do
          requires( :ok? )
        end

        initial_state :a
      end
      Klass.class_eval do
        attr_accessor :ok
        def ok?; ok; end
      end
      @obj = Klass.new
      @binding = @obj.state_fu
      @event = @machine.events[:go]
      @a = @machine.states[:a]
      @b = @machine.states[:b]
    end

    describe "when no block is supplied for the requirement" do

      it "should have an event named :go" do
        @machine.events[:go].requirements.should == [:ok?]
        @machine.events[:go].targets.should_not be_blank
        @machine.events[:go].origins.should_not be_blank        
        @machine.states.map(&:name).sort_by(&:to_s).should == [:a, :b]
        @a.should be_kind_of( StateFu::State )
        @event.should be_kind_of( StateFu::Event )
        @event.origins.map(&:name).should == [:a]
        @binding.current_state.should == @machine.states[:a]
        @event.from?( @machine.states[:a] ).should be_true
        @machine.events[:go].from?( @binding.current_state ).should be_true
        @binding.events.should_not be_empty
      end


      it "should contain the event in @binding.valid_events if @obj.ok? is true" do
        @obj.ok = true
        @binding.current_state.should == @machine.initial_state
        @binding.events.should == @machine.events
        @binding.valid_events.should == [@event]
      end

      it "should not contain :go in @binding.valid_events if !@obj.ok?" do
        @obj.ok = false
        @binding.events.should == @machine.events
        @binding.valid_events.should == []
      end

      it "should raise a RequirementError if requirements are not satisfied" do
        @obj.ok = false
        lambda do
          @obj.state_fu.fire_transition!( :go )
        end.should raise_error( StateFu::RequirementError )
      end

    end # no block

    describe "when a block is supplied for the requirement" do

      it "should be a valid event if the block is true " do
        @machine.named_procs[:ok?] = Proc.new() { true }
        @binding.valid_events.should == [@event]

        @machine.named_procs[:ok?] = Proc.new() { |binding| true }
        @binding.valid_events.should == [@event]

      end

      it "should not be a valid event if the block is false" do
        @machine.named_procs[:ok?] = Proc.new() { false }
        @binding.valid_events.should == []

        @machine.named_procs[:ok?] = Proc.new() { |binding| false }
        @binding.valid_events.should == []
      end

    end # block supplied

  end # machine w/guard conditions

  describe "A binding for a machine with a state transition requirement" do
    before do
      @machine = Klass.state_fu_machine do
        event( :go, :from => :a, :to => :b )
        state( :b ) do
          requires :entry_ok?
        end
      end
      Klass.class_eval do
        attr_accessor :entry_ok
        def entry_ok?
          entry_ok
        end
      end

      @obj = Klass.new
      @binding = @obj.state_fu
      @obj.entry_ok = true
      @event = @machine.events[:go]
      @a = @machine.states[:a]
      @b = @machine.states[:b]
    end

    describe "when no block is supplied for the requirement" do

      it "should be valid if @binding.valid_transitions' values includes the state" do
        t = @binding.transition([@event, @b])
        @binding.valid_next_states.should == [@b]
      end

      it "should be invalid if @obj.entry_ok? is false" do
        @obj.entry_ok = false
        @b.entry_requirements.should == [:entry_ok?]
        @binding.valid_next_states.should == []
      end

      it "should be valid if @obj.entry_ok? is true" do
        @obj.entry_ok = true
        @binding.valid_next_states.should == [@b]
      end

    end # no block

    describe "when a block is supplied for the requirement" do

      it "should be a valid event if the block is true " do
        @machine.named_procs[:entry_ok?] = Proc.new() { true }
        @binding.valid_next_states.should == [@b]

        @machine.named_procs[:entry_ok?] = Proc.new() { |binding| true }
        @binding.valid_next_states.should == [@b]
      end

      it "should not be a valid event if the block is false" do
        @machine.named_procs[:entry_ok?] = Proc.new() { false }
        @binding.valid_next_states.should == []

        @machine.named_procs[:entry_ok?] = Proc.new() { |binding| false }
        @binding.valid_next_states.should == []
      end

    end # block supplied
  end # machine with state transition requirement

  describe "a hook method accessing the transition, object, binding and arguments to fire!" do
    before do
      reset!
      make_pristine_class("Klass")
      @machine = Klass.state_fu_machine do
        event(:run, :from => :start, :to => :finish ) do
          execute( :run_exec )
        end
      end # machine
      @obj = Klass.new()
    end # before

    describe "a method defined on the stateful object" do

      it "should be able to call methods on the transition mixed in via machine.helper" do
        t1 = @obj.state_fu.transition( :run)
        t1.should_not respond_to(:my_rad_method)

        @machine.helper :my_rad_helper
        module ::MyRadHelper
          def my_rad_method( x )
            x
          end
        end
        t2 = @obj.state_fu.transition( :run )
        t2.should respond_to( :my_rad_method )
        t2.my_rad_method( 6 ).should == 6

        @machine.instance_eval do
          helpers.pop
        end
        t3 = @obj.state_fu.transition( :run )

        # triple check for contamination
        t1.should_not respond_to(:my_rad_method)
        t2.should     respond_to(:my_rad_method)
        t3.should_not respond_to(:my_rad_method)
      end

      it "should be able to access the args / options passed to fire! via transition.args" do
        # NOTE a trailing hash gets munged into options - not args
        args = [:a, :b, { 'c' => :d }]
        Klass.state_fu_machine do
          event(:run, :from => :start, :to => :finish ) do
            execute( :run_exec ) do |t|
              t.args.should == [:a, :b, {'c' => :d}]
              t.options.should == {:c => :d} # options are symbolized
            end
          end
        end
        trans = @obj.state_fu.run!( *args )
        trans.should be_accepted
      end
    end # method defined on object

    describe "a block passed to binding.transition" do
      
      it "should not be possible unless it's made less confusing" do
        pending "wtf is the use case?"
      end
    end

  end # args with fire!

  describe "next_transition" do
    describe "when there are multiple events but only one is fireable?" do
      before do
        reset!
        make_pristine_class("Klass")
        @machine = Klass.state_fu_machine do
          initial_state :alive do
            event :impossibility do
              to :afterlife
              requires :truth_of_patent_falsehoods? do
                false
              end
            end

            event :inevitability do
              to :plain_old_dead
            end
          end
        end
        @obj     = Klass.new()
        @binding = @obj.state_fu
        @binding.events.length.should == 2
      end

      describe "when the fireable? event has only one target" do
        it "should return a transition for the fireable event & its target" do
          @machine.events[:inevitability].targets.length.should == 1
          t = @binding.next_transition
          t.should be_kind_of( StateFu::Transition )
          t.from.should  == @binding.current_state
          t.to.should    == @machine.states[:plain_old_dead]
          t.event.should == @machine.events[:inevitability]
        end
      end

      describe "when the fireable? event has multiple targets but only one can be entered" do
        before do
          reset!
          make_pristine_class("Klass")
          @machine = Klass.state_fu_machine do
            initial_state :alive

            state :cremated

            state :buried do
              requires :plot_at_cemetary? do
                false
              end
            end

            event :inevitability do
              from :alive
              to :cremated, :buried
            end
          end
          @obj     = Klass.new()
          @binding = @obj.state_fu
          @machine.events[:inevitability].should be_kind_of(StateFu::Event)
          @binding.valid_events.map(&:name).should == [@machine.events[:inevitability]].map(&:name)
          @binding.valid_events.should == [@machine.events[:inevitability]]
          @binding.valid_transitions.map(&:target).map(&:name).should == [:cremated]
        end # before

        it "should return a transition for the fireable event & the enterable target" do
          t = @binding.next_transition
          t.should be_kind_of( StateFu::Transition )
          t.from.should  == @binding.current_state
          t.to.should    == @machine.states[:cremated]
          t.event.should == @machine.events[:inevitability]
        end
      end

      describe "when the fireable? event has multiple targets and more than one can be entered" do
        before do
          @machine.lathe do
            event :inevitability do
              to :cremated, :buried
            end
          end
          @obj     = Klass.new()
          @binding = @obj.state_fu
        end

        it "should not return a transition" do
          t = @binding.next_transition
          t.should be_nil
        end

        it "should raise TransitionNotFound if next! is called" do
          lambda { @binding.next! }.should raise_error( StateFu::TransitionNotFound )
        end
      end

    end
  end
end

