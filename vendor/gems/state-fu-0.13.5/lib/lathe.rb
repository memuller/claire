module StateFu
  # A Lathe parses and a Machine definition and returns a freshly turned
  # Machine.
  #
  # It provides the means to define the arrangement of StateFu objects
  # ( eg States and Events) which comprise a workflow, process,
  # lifecycle, circuit, syntax, etc.
  class Lathe

    # @state_or_event can be either nil (the main Lathe for a Machine)
    # or contain a State or Event (a child lathe for a nested block)

    attr_reader :machine, :state_or_event, :options

    # you don't need to call this directly.
    def initialize( machine, state_or_event = nil, options={}, &block )
      @machine        = machine
      @state_or_event = state_or_event
      @options        = options.symbolize_keys!

      # extend ourself with any previously defined tools
      machine.tools.inject_into( self )

      if state_or_event
        state_or_event.apply!( options )
      end
      if block_given?
        if block.arity == 1
          if state_or_event
            yield state_or_event
          else
            raise ArgumentError
          end
        else
          instance_eval( &block )
        end
      end
    end

    #
    # utility methods
    #

    # a 'child' lathe is created by apply_to, to deal with nested
    # blocks for states / events ( which are state_or_events )
    def nested?
      !!state_or_event
    end
    alias_method :child?, :nested?

    # is this the toplevel lathe for a machine?
    def master?
      !nested?
    end

    # get the top level Lathe for the machine
    def master_lathe
      machine.lathe
    end

    alias_method :context, :state_or_event

    def context_state
      state_or_event if state_or_event.is_a?(State)
    end

    def context_event
      state_or_event if state_or_event.is_a?(Event)
    end


    #
    # methods for extending the DSL
    #

    # helpers are mixed into all binding / transition contexts
    def helper( *modules )
      machine.helper *modules
    end

    # helpers are mixed into all binding / transition contexts
    def tool( *modules, &block )
      machine.tool *modules
      if block_given?
        tool = Module.new
        tool.module_eval &block
        machine.tools << tool
      end
      # inject them into self for immediate use
      modules.flatten.extend( ToolArray ).inject_into( self )
    end
    alias_method :extend_dsl, :tool

    #
    # event definition methods
    #

    # Defines an event. Any options supplied will be added to the event,
    # except :from and :to which are used to define the origin / target
    # states. Successive invocations will _update_ (not replace) previously
    # defined events; origin / target states and options are always
    # accumulated, not clobbered.
    #
    # Several different styles of definition are available. Consult the
    # specs / features for examples.

    def event( name, options={}, &block )
      options.symbolize_keys!
      valid_in_context( State, nil )
      if nested? && state_or_event.is_a?(State) # in state block
        targets  = options.delete(:to) || options.delete(:transitions_to)
        evt      = define_event( name, options, &block )
        evt.from state_or_event unless state_or_event.nil?
        evt.to( targets ) unless targets.nil?
        evt
      else # in master lathe
        origins = options.delete( :from )
        targets = options.delete( :to ) || options.delete(:transitions_to)
        evt     = define_event( name, options, &block )
        evt.from origins unless origins.nil?
        evt.to   targets unless targets.nil?
        evt
      end
    end

    # compatibility methods for activemodel state machine ##############
    def transitions(options={})
      valid_in_context(Event)
      options.symbolize_keys!

      target  = options[:to]
      origins = options[:from]
      hook    = options[:on_transition]
      evt     = state_or_event

      if hook
        evt.lathe() { triggers hook }
      end
      #
      # TODO do some type checking
      #
      if origins && target
        evt.add_to_sequence origins, target
      end
      evt
    end


    def state_event name, options={}, &block
      valid_in_context State
      options.symbolize_keys!
      state    = state_or_event
      targets  = options.delete(:to) || options.delete(:transitions_to)
      evt      = define_state_or_event( Event, state.own_events, name, options, &block)
      evt.from state
      evt.to(targets) unless targets.nil?
      evt
    end

    def event name, options={}, &block
      options.symbolize_keys!
      valid_in_context State, nil
      if nested? && state_or_event.is_a?(State)  # in state block
        targets  = options.delete(:to) || options.delete(:transitions_to)
        evt      = define_event name, options, &block
        evt.from state_or_event unless state_or_event.nil?
        evt.to   targets  unless targets.nil?
        evt
      else # in master lathe
        origins = options.delete(:from)|| options.delete(:transitions_from)
        targets = options.delete(:to)  || options.delete(:transitions_to)
        evt     = define_event name, options, &block
        evt.from origins unless origins.nil?
        evt.to   targets unless targets.nil?
        evt
      end
    end

    # define an event or state requirement.
    # options:
    #  :on => :entry|:exit|array (state only) - check requirement on state entry, exit or both?
    #     default = :entry
    #  :message => string|proc|proc_name_symbol - message to be returned on requirement failure.
    #     if a proc or symbol (named proc identifier), evaluated at runtime; a proc should
    #     take one argument, which is a StateFu::Transition.
    #  :msg => alias for :message, for the morbidly terse

    def requires( *args, &block )
      valid_in_context Event, State
      options = args.extract_options!.symbolize_keys!
      options.assert_valid_keys :on, :message, :msg
      names   = args
      if block_given? && args.length > 1
        raise ArgumentError.new("cannot supply a block for multiple requirements")
      end
      on = nil
      names.each do |name|
        raise ArgumentError.new(name.inspect) unless name.is_a?(Symbol)
        case state_or_event
        when State
          on ||= [(options.delete(:on) || [:entry])].flatten
          state_or_event.entry_requirements << name if on.include?( :entry )
          state_or_event.exit_requirements  << name if on.include?( :exit  )
        when Event
          state_or_event.requirements << name
        end
        if block_given?
          machine.named_procs[name] = block
        end
        if msg = options.delete(:message) || options.delete(:msg)
          raise ArgumentError, msg.inspect unless [String, Symbol, Proc].include?(msg.class)
          machine.requirement_messages[name] = msg
        end
      end
    end
    alias_method :guard,        :requires
    alias_method :must,         :requires
    alias_method :must_be,      :requires
    alias_method :needs,        :requires

    # create an event from *and* to the current state.
    # Creates a loop, useful (only) for hooking behaviours onto.
    def cycle name=nil, options={}, &block
      _state = nil
      if name.is_a?(Hash) && options.empty?
        options = name
        name    = nil
      end
      if _state = options.delete(:state)
        valid_unless_nested("when :state is supplied")
      else
        _state = state_or_event
        valid_in_context( State, "unless :state is supplied" )
      end

      name ||= options.delete :on
      name ||= "cycle_#{_state.to_sym}"
      evt = define_event( name, options, &block )
      evt.from _state
      evt.to   _state
      evt
    end

    #
    # state definition
    #

    # define the initial_state (otherwise defaults to the first state mentioned)
    def initial_state *args, &block
      valid_unless_nested()
      machine.initial_state= state( *args, &block)
    end

    # define a state; given a block, apply the block to a Lathe for the state
    def state name, options={}, &block
      valid_unless_nested()
      define_state( name, options, &block )
    end

    # define a named proc
    def define method_name, &block
      machine.named_procs[method_name] = block
    end
    alias_method :named_proc, :define

    #
    # Event definition
    #

    # set the origin state(s) of an event (or, given a hash of symbols / arrays
    # of symbols, set both the origins and targets)
    # from :my_origin
    # from [:column_a, :column_b]
    # from :eden => :armageddon
    # from [:beginning, :prelogue] => [:ende, :prologue]
    def from *args, &block
      valid_in_context Event
      state_or_event.from( *args, &block )
    end

    # set the target state(s) of an event
    # to :destination
    # to :target_a, :target_b
    # to [:end, :finale, :intermission]
    def to *args, &block
      valid_in_context Event
      state_or_event.to( *args, &block )
    end

    #
    # define chained events and states succinctly
    # usage: chain 'state1 -event1-> state2 -event2-> state3'
    def chain string
      rx_word    = /([a-zA-Z0-9_]+)/
      rx_state   = /^#{rx_word}$/
      rx_event   = /^(?:-|>)#{rx_word}-?>$/
      previous   = nil
      string.split.each do |chunk|
        case chunk
        when rx_state
          current = state $1
          if previous.is_a? Event
            previous.to current
          end
        when rx_event
          current = event $1
          if previous.is_a? State
            current.from previous
          end
        else
          raise ArgumentError, "'#{chunk}' is not a valid token"
        end
        previous = current
      end
    end

    # chain_states :a => [:b,:c], :c => :d, :c => :d
    # chain_states :a,:b,:c,:d, :a => :c
    def connect_states *array
      array.flatten!
      hash = array.extract_options!.symbolize_keys!
      array.inject(nil) do |origin, target|
        state target
        if origin
          event "#{origin.to_sym}_to_#{target.to_sym}", :from => origin, :to => target
        end
        origin = target
      end
      hash.each do |origin, target|
        event "#{origin.to_sym}_to_#{target.to_sym}", :from => origin, :to => target
      end
    end
    alias_method :connect, :connect_states

    #
    # Define a series of states at once, or return and iterate over all states yet defined
    #
    # states :a, :b, :c, :colour => "purple"
    # states(:ALL) do
    #
    # end
    def states *args, &block
      valid_unless_nested()
      each_state_or_event 'state', *args, &block
    end
    alias_method :all_states, :states
    alias_method :each_state, :states

    #
    # Define a series of events at once, or return and iterate over all events yet defined
    #
    def events *args, &block
      valid_in_context nil, State
      each_state_or_event 'event', *args, &block
    end
    alias_method :all_events, :events
    alias_method :each_event, :events

    # Bunch of silly little methods for defining events
    #:nodoc

    def before     *a, &b; valid_in_context Event; define_hook :before,     *a, &b; end
    def on_exit    *a, &b; valid_in_context State; define_hook :exit,       *a, &b; end
    def execute    *a, &b; valid_in_context Event; define_hook :execute,    *a, &b; end
    def on_entry   *a, &b; valid_in_context State; define_hook :entry,      *a, &b; end
    def after      *a, &b; valid_in_context Event; define_hook :after,      *a, &b; end
    def accepted   *a, &b; valid_in_context State; define_hook :accepted,   *a, &b; end

    def before_all *a, &b; valid_in_context nil;   define_hook :before_all, *a, &b; end
    def after_all  *a, &b; valid_in_context nil;   define_hook :after_all,  *a, &b; end

    alias_method :after_everything,  :after_all
    alias_method :before_everything, :before_all

    def after_all *a
    end

    def will *a, &b
      valid_in_context State, Event
      case state_or_event
      when State
        define_hook :entry, *a, &b
      when Event
        define_hook :execute, *a, &b
      end
    end
    alias_method :fire,     :will
    alias_method :fires ,   :will
    alias_method :firing,   :will
    alias_method :cause,    :will
    alias_method :causes,   :will
    alias_method :triggers, :will
    alias_method :trigger,  :will
    alias_method :trigger,  :will

    alias_method :on_change, :accepted
    #
    #
    #

    private

    # require that the current state_or_event be of a given type
    def valid_in_context *valid_types
      if valid_types.last.is_a?(String)
        msg = valid_types.pop << " "
      else
        msg = ""
      end
      unless valid_types.include?( state_or_event.class ) || valid_types.include?(nil) && state_or_event.nil?
        v = valid_types.dup.map do |t|
          {
            nil   => "if not nested inside a block",
            State => "inside a state definition block",
            Event => "inside an event definition block"
          }[t]
        end
        msg << "this command is only valid " << v.join(',')
        raise ArgumentError, msg
      end
    end

    # ensure this is not a child lathe
    def valid_unless_nested(msg = nil)
      valid_in_context( nil, msg )
    end

    # instantiate a child Lathe and apply the given block
    def apply_to state_or_event, options, &block
      StateFu::Lathe.new( machine, state_or_event, options, &block )
      state_or_event
    end

    # abstract method for defining states / events
    def define_state_or_event klass, collection, name, options={}, &block
      name = name.to_sym
      req  = nil
      msg  = nil
      options.symbolize_keys!

      # allow requirements and messages to be added as options
      if k = [:requires, :guard, :must, :must_be, :needs].detect {|k| options.has_key?(k) }
        # Logging.debug("removing option #{k} - will use as requirement ..")
        req = options.delete(k)
        msg = options.delete(:message) || options.delete(:msg)
        raise ArgumentError unless msg.nil? || req.is_a?(Symbol)
        raise ArgumentError unless ([req, msg].map(&:class) - [String, Symbol, Proc, NilClass]).empty?
      end
      # TODO? allow hooks to be defined as options

      unless state_or_event = collection[name]
        state_or_event  = klass.new machine, name, options
        collection << state_or_event
      end

      apply_to state_or_event, options, &block

      if req # install requirements
        state_or_event.requirements << req
        machine.requirement_messages[req] = msg if msg
      end

      state_or_event
    end

    #:nodoc
    def define_state name, options={}, &block
      collection = machine.states
      define_state_or_event State, collection, name, options, &block
    end

    #:nodoc
    def define_event name, options={}, &block
      collection = machine.events
      define_state_or_event Event, collection, name, options, &block
    end

    #:nodoc
    def define_hook slot, *method_names, &block
      raise "wtf" unless machine.is_a?(Machine)
      hooks = (slot.to_s =~ /_all/ ? machine.hooks : state_or_event.hooks)
      unless hooks.has_key? slot
        raise ArgumentError, "invalid hook type #{slot.inspect} for #{state_or_event.class}"
      end
      if block_given?
        method_name = method_names.first
        # unless (-1..1).include?( block.arity )
        #   raise ArgumentError, "unexpected block arity: #{block.arity}"
        # end
        case method_name
        when Symbol
          machine.named_procs[method_name] = block
          hook = method_name
        when nil
          hook = block
          # allow only one anonymous hook per slot in the interests of
          # sanity - replace any pre-existing ones
          hooks[slot].delete_if { |h| Proc === h }
        else
          raise ArgumentError.new method_name.inspect
        end
        hooks[slot] << hook
      else
        method_names.each do |method_name|
          if method_name.is_a? Symbol # no block
            hook = method_name
            # prevent duplicates
            hooks[slot].delete_if { |h| hook == h }
            hooks[slot] << hook
          else
            raise ArgumentError, "#{method_name.class} is not a symbol"
          end
        end
      end

    end

    #:nodoc
    def each_state_or_event type, *args, &block
      options = args.extract_options!.symbolize_keys!
      if args.empty? || args  == [:ALL]
        args = machine.send("#{type}s").except options.delete(:except)
      end
      mod = case type.to_s
            when 'state'
              StateArray
            when 'event'
              EventArray
            end
      args.map do |name|
        self.send type, name, options.dup, &block
      end.extend(mod)
    end

  end
end
