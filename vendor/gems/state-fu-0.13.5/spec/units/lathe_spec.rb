require File.expand_path("#{File.dirname(__FILE__)}/../helper")

describe StateFu::Lathe do
  include MySpecHelper

  before do
    reset!
    make_pristine_class('Klass')
    @machine = StateFu::Machine.new()
    @state   = Object.new()
    @event   = Object.new()

    @machine.should_receive(:tools).any_number_of_times.and_return([].extend( StateFu::ToolArray ))
    @lathe = StateFu::Lathe.new( @machine )
    @states = [].extend StateFu::StateArray    
    @machine.should_receive(:states).any_number_of_times.and_return(@states)
    @events = [].extend StateFu::EventArray
    @machine.should_receive(:events).any_number_of_times.and_return(@events)
  end

  describe "constructor" do
    it "should create a new Lathe given valid arguments" do
      lathe = StateFu::Lathe.new( @machine )
      lathe.should be_kind_of( StateFu::Lathe )
      lathe.machine.should  == @machine
      lathe.state_or_event.should == nil
      lathe.options.should  == {}
    end

    it "should accept a state_or_event (state / event ) and if given one, be a child" do
      options = {}
      @state.should_receive(:apply!).with(options)
      lathe = StateFu::Lathe.new( @machine, @state )
      lathe.should be_kind_of( StateFu::Lathe )
      lathe.machine.should  == @machine
      lathe.state_or_event.should == @state
      lathe.options.should  == {}
      lathe.should be_child
    end
  end

  describe "lathe instance with no state_or_event (master lathe for a machine)" do
    before do
    end

    it "should be master?" do
      @lathe.should be_master
      @lathe.should_not be_child
    end

    describe "defining a state with .state" do

      it "should add a state to the lathe's machine.states if the named state does not exist" do
        @lathe.state( :wibble )
        @machine.states.should_not be_empty
        @machine.states.length.should == 1
        s = @machine.states.first
        s.should be_kind_of( StateFu::State )
        s.name.should == :wibble
      end

      it "should create a child lathe and apply the options and block if supplied" do
        options = {:banana => :flower}
        @state = Object.new()
        @child = Object.new()
        StateFu::State.should_receive(:new).with(@machine, :wobble, options).and_return(@state)
        StateFu::Lathe.should_receive(:new).with(@machine, @state, options).and_return(@child)        
        # TODO mock the block 
        @lathe.state( :wobble, options )
      end

      it "should update the named state if it exists" do
        @lathe.state( :wibble, { :nick => :wobble } )
        @machine.states.should_not be_empty
        @machine.states.length.should == 1
        s = @machine.states.first
        @lathe.state( :wibble, { :meta => :voodoo } ).should == s
        s.options[:meta].should == :voodoo
        s.options[:nick].should == :wobble
      end

      it "should return the named state" do
        s = @lathe.state( :wibble, { :nick => :wobble } )
        s.should be_kind_of( StateFu::State )
        s.name.should == :wibble
      end
    end # .state

    describe "defining multiple states with .states" do

      it "should add all states named to the machine if they dont exist" do
        @lathe.states :a, :b, :c, {:group => :alphabet} do
          requires :jackson_five
        end
        @machine.states.length.should == 3
        @machine.states.map(&:name).should == [:a, :b, :c]
        @machine.states.each {|s| s.options[:group].should == :alphabet }
        @machine.states.each {|s| s.entry_requirements.should include(:jackson_five) }
      end

      it "should apply the block / options to each named state if it already exists" do
        @lathe.state :lemon do
          requires :squinty_face
        end
        @lathe.states :mango, :orange, :lemon, {:group => :fruit } do
          requires :knife
          on_entry :peel
        end
        @lathe.states :orange, :lemon, :mandarin,  { :type  => :citrus } do
          requires :juicer
          on_entry :juice
        end
        states = @machine.states
        states[:mango   ].options.should == { :group => :fruit }
        states[:lemon   ].options.should == { :group => :fruit, :type => :citrus }
        states[:mandarin].options.should == { :type => :citrus }
        states[:mango   ].entry_requirements.should == [:knife]
        states[:lemon   ].entry_requirements.should == [:squinty_face, :knife, :juicer]
        states[:mandarin].entry_requirements.should == [:juicer]
        states[:mango   ].hooks[:entry].should == [:peel]
        states[:lemon   ].hooks[:entry].should == [:peel, :juice]
        states[:mandarin].hooks[:entry].should == [:juice]
      end

      it "should apply to all existing states given :ALL" do
        @lathe.states :hot, :cold
        names = []
        @lathe.states :ALL do |s|
          names << s.name
        end
        names.should == [:hot, :cold]
      end

      it "should apply to all existing states given no arguments" do
        @lathe.states :hot, :cold
        names = []
        @lathe.states do |s|
          names << s.name
        end
        names.should == [:hot, :cold]
      end

      # TODO
      it "should apply to all existing states except those named given :except => [...]" do
        @lathe.states :hot, :cold, :warm

        names = []
        @lathe.states :ALL, :except => :warm do |s|
          names << s.name
        end
        names.should == [:hot, :cold]

        names = []
        @lathe.states :ALL, :except => [:hot, :cold] do |s|
          names << s.name
        end
        names.should == [:warm]
      end

      it "should return an array of states with extensions" do
        x = @lathe.states :hot, :cold, :warm
        x.should be_kind_of( Array )
        x.length.should == 3
        x.each {|e| e.should be_kind_of( StateFu::State ) }
        x.map(&:name).should == [:hot, :cold, :warm]
        x.except(:warm).map(&:name).should == [:hot, :cold]
      end
    end # states

    describe "defining an event with .event" do

      it "should add a event to the lathe's machine.events if the named event does not exist" do
        @lathe.event( :wibble )
        @machine.events.should_not be_empty
        @machine.events.length.should == 1
        s = @machine.events.first
        s.should be_kind_of( StateFu::Event )
        s.name.should == :wibble
      end

      it "should create a child lathe and apply the options and block if supplied" do
        options = {:banana => :flower}
        @event = Object.new()
        @child = Object.new()
        # TODO mock the block 
        StateFu::Event.should_receive(:new).with(@machine, :wobble, options).and_return(@event)
        StateFu::Lathe.should_receive(:new).with(@machine, @event, options).and_return(@child)                
        @lathe.event( :wobble, options )
      end

      it "should update the named event if it exists" do
        @lathe.event( :wibble )
        @machine.events.should_not be_empty
        @machine.events.length.should == 1
        s = @machine.events.first
        @lathe.event( :wibble, { :meta => :voodoo } ).should == s
        s.options[:meta].should == :voodoo
      end

      it "should create states mentioned in the event definition and add them to machine.states" do
        @machine = StateFu::Machine.new( :snoo )
        @lathe = StateFu::Lathe.new( @machine )
        @lathe.event(:wobble, :from => [:a, :b], :to => :c )
        @machine.events.should_not be_empty
        @machine.events.length.should == 1
        @machine.events.first.name.should == :wobble
        @machine.states.length.should == 3
        @machine.states.map(&:name).sort_by {|x| x.to_s }.should == [ :a, :b, :c]
        @machine.events[:wobble].origins.map(&:name).should == [:a,:b]
        @machine.events[:wobble].targets.map(&:name).should == [:c]
      end

      it "should allow definition of events using :from => {*origin => *target}" do
        @machine = StateFu::Machine.new( :hash_it_up )
        @lathe = StateFu::Lathe.new( @machine )
        e = @lathe.event(:snooze, :from => { :nine => :ten } )
        e.name.should == :snooze
        e.origins.length.should == 1
        e.origin.name.should == :nine
        e.targets.length.should == 1
        e.target.name.should == :ten
      end

    end # .event

    describe "defining multiple events with .events" do

      it "should add all events named to the machine if they dont exist" do
        @lathe.event :tickle
        @lathe.events :hit, :smack, :punch, {:group => :acts_of_violence} do
          requires :strong_stomach
        end
        e = @machine.events
        e.length.should == 4
        e.map(&:name).should == [:tickle, :hit, :smack, :punch]
        e[:tickle].options[:group].should == nil
        e[:punch ].options[:group].should == :acts_of_violence
        e[:tickle].requirements.should == []
        e[:punch ].requirements.should == [:strong_stomach]
      end

      it "should apply the block / options to each named event if it already exists" do
        @lathe.event :fart, { :socially_acceptable => false } do
          requires :tilt_to_one_side
          after :inhale_through_nose
        end

        @lathe.event :smile, { :socially_acceptable => true } do
          requires :teeth
          after :close_mouth
        end

        @lathe.events :smile, :fart, { :group => :human_actions } do
          requires :corporeal_body, :free_will
          after :blink
        end
        e = @machine.events
        e[:fart].options[:socially_acceptable].should == false
        e[:smile].options[:socially_acceptable].should == true
        e[:fart].requirements.should == [:tilt_to_one_side, :corporeal_body, :free_will]
        e[:smile].requirements.should == [:teeth, :corporeal_body, :free_will]
        e[:fart].hooks[:after].should == [:inhale_through_nose, :blink]
        e[:smile].hooks[:after].should == [:close_mouth, :blink]
      end

      it "should apply to all existing events given :ALL" do
        @lathe.events :spit, :run
        names = []
        @lathe.events :ALL do |s|
          names << s.name
        end
        names.should == [:spit, :run]
      end

      it "should apply to all existing events given no arguments" do
        @lathe.events :dance, :juggle
        names = []
        @lathe.events do |s|
          names << s.name
        end
        names.should == [:dance, :juggle]
      end

      # TODO
      it "should apply to all existing events except those named given :except => [...]" do
        @lathe.events :wink, :bow, :salute

        names = []
        @lathe.events :ALL, :except => :salute do |s|
          names << s.name
        end
        names.should == [:wink, :bow]

        names = []
        @lathe.events :ALL, :except => [:bow, :wink] do |s|
          names << s.name
        end
        names.should == [:salute]

      end

    end # events

    describe "initial_state" do

      it "should set the initial state to its argument, creating if it does not exist" do
        @machine.instance_eval do
          class << self
            attr_accessor :initial_state
          end
        end
        @machine.states.should be_empty
        @lathe.initial_state :bambi
        @machine.states.should_not be_empty
        @machine.states.length.should == 1
        @machine.states.first.name.should == :bambi
        @machine.initial_state.name.should == :bambi
        @lathe.initial_state :thumper
        @machine.states.length.should == 2
        @machine.states.map(&:name).should == [:bambi, :thumper]
        @machine.states.last.name.should == :thumper
        @machine.initial_state.name.should == :thumper
      end
    end

    describe "helper" do
      it "should call machine.helper *args" do
        @machine.should_receive(:helper).with( :fee, :fi, :fo, :fum )
        @lathe.helper( :fee, :fi, :fo, :fum )
      end
    end

  end # master lathe instance

  # child lathe - created and yielded within nested blocks in a
  # machine definition
  describe "a child lathe for a state" do
    before do
      @master = @lathe
      @state  = @lathe.state(:a)
      @lathe  = StateFu::Lathe.new( @machine, @state )
    end

    describe ".cycle( evt_name )" do
      before do
        @machine = StateFu::Machine.new( :snoo )
        @master  = StateFu::Lathe.new( @machine )
        @state   = @master.state(:a)
        @lathe   = StateFu::Lathe.new( @machine, @state )
      end

      it "should create a named event from and to the lathe's state_or_event (state)" do

        @machine.events.should be_empty
        @machine.states.length.should == 1
        @lathe.cycle(:rebirth)
        @machine.events.should_not be_empty
        @machine.states.length.should == 1
        cycle = @machine.events.first
        cycle.should be_kind_of( StateFu::Event )
        cycle.origins.should == [@state]
        cycle.targets.should == [@state]
      end

      it "should create an event with a default name if given no name" do
        @machine.events.should be_empty
        @machine.states.length.should == 1
        @lathe.cycle
        @machine.events.should_not be_empty
        @machine.states.length.should == 1
        e = @machine.events.first
        e.name.should == :cycle_a
        e.origins.should == [@state]
        e.targets.should == [@state]
      end

    end

    describe ".event(:name)" do
      before do
        @machine.should_receive(:find_or_create_states_by_name).with(@lathe.state_or_event).at_least(1).times.and_return(@lathe.state_or_event)        
      end

      it "should create the named event if it does not exist" do
        @machine.events.should be_empty
        @lathe.event(:poop)
        @machine.events.should_not be_empty
        @machine.events[:poop].should be_kind_of( StateFu::Event )
      end

      it "should update the named event if it does exist" do
        @lathe.machine.should == @machine
        @lathe.event(:poop)
        @machine.events[:poop].options.should == {}
        @lathe.event(:poop, :lick => :me )
        @machine.events[:poop].options[:lick].should == :me
      end

      it "should yield a created event given a block with arity 1" do
        @machine.events.length.should == 0
        @lathe.event(:poop) do |e| # yield the event
          e.should be_kind_of( StateFu::Event )
          e.name.should == :poop
          e.options[:called] = true
        end
        @machine.events.length.should == 1
        e = @machine.events[:poop]
        e.options[:called].should == true
      end

    end

    describe ".requires()" do

      before do
        @state.exit_requirements.should == []
        @state.entry_requirements.should == []
      end

      it "should add :method_name to state.entry_requirements given a name" do
        @lathe.requires( :method_name )
        @state.entry_requirements.should == [:method_name]
        @state.exit_requirements.should == []
      end


      it "should add :method_name to state.entry_requirements given a name and :on => :exit" do
        @lathe.requires( :method_name, :on => :exit )
        @state.exit_requirements.should == [:method_name]
        @state.entry_requirements.should == []
      end

      it "should add :method_name to entry_requirements and exit_requirements given a name and :on => [:entry, :exit]" do
        @lathe.requires( :method_name, :on => [:entry, :exit] )
        @state.exit_requirements.should == [:method_name]
        @state.entry_requirements.should == [:method_name]
      end

      it "should add multiple method_names if more than one is given" do
        @lathe.requires( :method_one, :method_two )
        @lathe.requires( :method_three, :method_four, :on => [:exit] )
        @state.entry_requirements.should == [:method_one, :method_two]
        @state.exit_requirements.should  == [:method_three, :method_four]
      end

      it "should add to machine.named_procs if a block is given" do
        class << @machine
          attr_accessor :named_procs
        end
        @machine.named_procs = {}
        block = lambda { puts "wee" }
        @machine.named_procs.should == {}
        @lathe.requires( :method_name, :on => [:entry, :exit], &block )
        @state.exit_requirements.should == [:method_name]
        @state.entry_requirements.should == [:method_name]
        @machine.named_procs[:method_name].should == block
      end

      it "should add a message to machine.requirement_messages if a string is given" do
        class << @machine
          attr_accessor :requirement_messages
        end
        @machine.requirement_messages = {}
        @lathe.requires( :method_one, :message => "Method one says no soup for you!" )
        @machine.should respond_to(:requirement_messages)
        @machine.requirement_messages.keys.should == [:method_one]
        @machine.requirement_messages.values.first.should be_kind_of( String )
      end

    end
  end # a child lathe for a state

  describe "a child lathe for an event" do
    before do
      @master = @lathe
      @event  = @lathe.event( :go )
      @lathe  = StateFu::Lathe.new( @machine, @event )
    end

    describe ".from" do
      it "should create any states mentioned which do not exist" do
        @machine.should_receive(:find_or_create_states_by_name).with(:a, :b).and_return([:a, :b])
        @lathe.from( :a, :b )
      end

      it "should set the origins to the result of machine.find_or_create_states_by_name" do
        @machine.should_receive(:find_or_create_states_by_name).with(:a, :b).and_return([:a, :b])
        @lathe.from( :a, :b )
        @event.origins.should == [:a, :b]
      end

      it "should accumulate @origins on successive invocations" do
        @machine.should_receive(:find_or_create_states_by_name).with(:a, :b).and_return([:a, :b])
        @machine.should_receive(:find_or_create_states_by_name).with(:x, :y).and_return([:x, :y])
        @lathe.from( :a, :b )
        @event.origins.should == [:a, :b]
        @lathe.from( :x, :y )
        @event.origins.should == [:a, :b, :x, :y]
      end

      it "should set / update both origin and target if a hash is given" do
        @machine.should_receive(:find_or_create_states_by_name).with(:a).and_return [:a] 
        @machine.should_receive(:find_or_create_states_by_name).with(:b).and_return [:b] 
        @machine.should_receive(:find_or_create_states_by_name).with(:a, :b).and_return([:a, :b])
        @machine.should_receive(:find_or_create_states_by_name).with(:x, :y).and_return([:x, :y])
        @lathe.from( :a => :b )
        @event.origin.should == :a
        @event.target.should == :b
        @lathe.from( { [:a, :b] => [:x, :y] })
        @event.origin.should == nil
        @event.target.should == nil
        @event.origins.should == [:a, :b]
        @event.targets.should == [:b, :x, :y] # accumulated total
      end
    end

    describe ".to" do
      it "should create any states mentioned which do not exist" do        
        @machine.should_receive(:find_or_create_states_by_name).with(:a, :b).and_return([:a, :b])
        @lathe.to( :a, :b )
      end

      it "should set the targets to the result of machine.find_or_create_states_by_name" do
        @machine.should_receive(:find_or_create_states_by_name).with(:a, :b).and_return([:a, :b])
        @lathe.to( :a, :b )
        @event.targets.should == [:a, :b]
      end

      it "should update @origins on successive invocations" do
        @machine.should_receive(:find_or_create_states_by_name).with(:a, :b).and_return([:a, :b])
        @machine.should_receive(:find_or_create_states_by_name).with(:x, :y).and_return([:x, :y])
        @lathe.to( :a, :b )
        @event.targets.should == [:a, :b]
        @lathe.to( :x, :y )
        @event.targets.should == [:a, :b, :x, :y] # accumulated targets
      end
    end

    describe ".requires()" do

      before do
        @event.requirements.should == []
      end

      it "should add :method_name to event.requirements given a name" do
        @lathe.requires( :method_name )
        @event.requirements.should == [:method_name]
      end

      it "should add to machine.named_procs if a block is given" do
        class << @machine
          attr_accessor :named_procs
        end
        @machine.named_procs = {}
        block = lambda { puts "wee" }
        @machine.named_procs.should == {}
        @lathe.requires( :method_name, &block )
        @event.requirements.should == [:method_name]
        @machine.named_procs[:method_name].should == block
      end

    end  # requires

  end # a child lathe for an event

end
