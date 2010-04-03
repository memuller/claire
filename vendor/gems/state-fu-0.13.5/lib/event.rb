module StateFu
  class Event < StateFu::Sprocket

    attr_reader :origins, :targets, :requirements, :sequence

    # called by Lathe when a new event is constructed
    def initialize(machine, name, options={})
      @requirements = [].extend ArrayWithSymbolAccessor    
      @sequence     = {}
      super( machine, name, options )
    end

    # Sequences: pretending events are state-local -
    # probably a bad idea but here for a "compatibility mode"
    # with eg the activemodel state machine
    
    # build a hash of target => [origins]
    def add_to_sequence origin_states, target_state
      origin_states = [origin_states].flatten
      existing = origin_states.select {|s| target_for_origin(s) }
      raise ArgumentError.new unless existing.empty? && !targets       
      @sequence[target_state] ||= []
      [origin_states].flatten.each do |o|
        @sequence[target_state] << o
      end
      @sequence
    end

    def sequence?
      !sequence.empty?
    end

    def target_for_origin origin_state
      raise ArgumentError.new if origin_state.nil?
      name = sequence.detect do |k,v| 
        v.include?(origin_state.to_sym)
      end[0] rescue nil
      machine.states[name] if name
    end
    

    def can_transition_from?(origin_state) 
      ( origins && origins.include?(origin_state.to_sym) && !targets.blank?) ||
        target_for_origin(origin_state)
    end    
  
    # the names of all possible origin states
    def origin_names
      origins ? origins.map(&:to_sym) : nil
    end

    # the names of all possible target states
    def target_names
      targets ? targets.map(&:to_sym) : nil
    end

    # tests if a state or state name is in the list of targets
    def to?( state )
      target_names.include?( state.to_sym )
    end

    # tests if a state or state name is in the list of origins
    def from?( state )
      origin_names.include?( state.to_sym ) || target_for_origin(state)
    end
    
    def cycle?
      origin && (origin == target)
    end

    # *adds to* the origin states given a list of symbols / States
    def origins=( *args )
      update_state_collection( '@origins', *args )
    end

    # *adds to* the target states given a list of symbols / States
    def targets=( *args )
      update_state_collection( '@targets', *args )
    end

    # if there is a single state in #origins, returns it
    def origin
      origins && origins.length == 1 && origins[0] || nil
    end

    # if there is a single state in #origins, returns it
    def target
      targets && targets.length == 1 && targets[0] || nil
    end

    # a simple event has exactly one target, and any number of
    # origins. It's simple because it can be triggered without
    # supplying a target name - ie, <tt>go!<tt> vs <tt>go!(:home)<tt>
    def simple?
      !! ( origins && target || sequence? )
    end

    def fireable?( transition )
      transition.valid?(true)
    end


    #
    # Lathe methods
    #

    # adds an event requirement.
    # DOCME // TODO - can this be removed?
    def requires( *args, &block )
      lathe.requires( *args, &block )
    end

    # generally called from a Lathe. Sets the origin(s) and optionally
    # target(s) - that is, if you supply the :to option, or a single element
    # hash of origins => targets ) of the event. Both origins= and
    # targets= are accumulators.
    def from *args
      options = args.extract_options!.symbolize_keys!
      args.flatten!
      to = options.delete(:to) || options.delete(:transitions_to)
      if args.empty? && !to
        if options.length == 1
          self.origins = options.keys[0]
          self.targets = options.values[0]
        else
          raise options.inspect
        end
      else
        self.origins = *args
        self.targets = to unless to.nil?
      end
    end

    # sets the target states for the event.
    def to *args
      options = args.extract_options!.symbolize_keys!
      args.flatten!
      raise options.inspect unless options.empty?
      self.targets= *args
    end

    alias_method :transitions_to,   :to
    alias_method :transitions_from, :from

    #
    # misc
    # 
    
    # display nice and short
    def inspect
      s = self.to_s
      s = s[0,s.length-1]
      display_hooks = hooks.dup
      display_hooks.each do |k,v|
        display_hooks.delete(k) if v.empty?
      end
      unless display_hooks.empty?
        s << " hooks=#{display_hooks.inspect}"
      end
      unless requirements.empty?
        s << " requirements=#{requirements.inspect}"
      end
      s << " targets=#{targets.map(&:to_sym).inspect}" if targets
      s << " origins=#{origins.map(&:to_sym).inspect}" if origins
      s << ">"
      s
    end

    private

    # internal method which accumulates states into an instance
    # variable with successive invocations.
    # ensures that calling #from multiple times adds to, rather than
    # clobbering, the list of origins / targets.
    def update_state_collection( ivar_name, *args)
      raise ArgumentError if sequence?      
      new_states = if [args].flatten == [:ALL]
            machine.states
          else
            machine.find_or_create_states_by_name( *args.flatten )
          end
      unless new_states.is_a?( Array )
        new_states = [new_states]
      end
      existing  = instance_variable_get( ivar_name )
      # return existing if new_states.empty?
      new_value = ((existing || [] ) + new_states).flatten.compact.uniq.extend( StateArray )
      instance_variable_set( ivar_name, new_value )
    end

  end
end
