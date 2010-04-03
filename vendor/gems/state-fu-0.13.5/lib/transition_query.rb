module StateFu
  class TransitionQuery
    attr_accessor :binding, :options, :result, :args, :block

    def initialize(binding, options={})
      defaults = { :valid => true, :cyclic => nil }
      @options = defaults.merge(options).symbolize_keys
      @binding = binding
    end

    include Enumerable
    
    def each *a, &b
      result.each *a, &b
    end

    # calling result() will cause the set of transitions to be calculated -
    # the cat will then be either dead or alive; until then it's anyone's guess.
    
    # this is a cheap way of passing any call to #each, #length, etc to result().
    # TODO: be explicit, eg using delegate, and remove method_missing.   
    def method_missing(method_name, *args, &block)
      if result.respond_to?(method_name, true)
        result.__send__(method_name, *args, &block)
      else
        super(method_name, *args, &block)
      end
    end
                
    # prepare the query with arguments / block
    # so that they can be applied to the transition once one is selected
    def with(*args, &block)
      @args  = args
      @block = block if block_given?
      self
    end
    
    #
    # Chainable Filters
    #     
    
    def cyclic
      @options.merge! :cyclic => true
      self
    end

    def not_cyclic
      @options.merge! :cyclic => false
      self
    end

    def valid
      @options.merge! :valid => true
      self
    end

    def not_valid
      @options.merge! :valid => false
      self
    end
    alias_method :invalid, :not_valid

    def to state
      @options.merge! :target => state
      self
    end

    def for_event event
      @options.merge! :event => event
      self
    end

    def simple
      @options.merge! :simple => true
      self
    end
    
    #
    # Means to an outcome
    #
    
    # find a transition by event and optionally (optional if it can be inferred) target.
    def find(destination=nil, &block)
      # use the prepared event & target, and block, if none are supplied
      event, target = destination.nil? ? [options[:event], options[:target]] : parse_destination(destination)
      block ||= @block
      returning Transition.new(binding, event, target, &block) do |transition|
        if @args
          transition.args = @args 
        end
      end        
    end
  
    def singular
      result.first if result.length == 1
    end

    def singular?
      !!singular
    end

    def next
      @options[:cyclic] ||= false
      singular
    end
    
    def next_state
      @options[:cyclic] ||= false
      if result.map(&:target).uniq.length == 1
        result.first.target
      end
    end

    def next_event
      @options[:cyclic] ||= false
      if result.map(&:event).uniq.length == 1
        result.first.event
      end
    end
    
    def events
      map {|t| t.event }.extend EventArray
    end

    def targets
      map {|t| t.target }.extend StateArray
    end

    private

    # extend result with this to provide a few conveniences   
    module Result
      def states
        map(&:target).uniq.extend StateArray
      end
      alias_method :targets, :states
      alias_method :next_states, :states

      def events
        map(&:event).uniq.extend EventArray
      end
    end # Result

    # looks a little complex because of all the places that previously set
    # options can filter the set of transitions - but all it's doing is
    # looping over each event, and each event's possible targets, and building
    # a list of transitions.
    
    def result
      @result = binding.events.select do |e| 
        case options[:cyclic]
        when true
          e.cycle?
        when false
          !e.cycle?
        else
          true
        end
      end.map do |event|
        next if options[:event] and event != options[:event]
        returning [] do |ts|

          # TODO hmm ... "sequences" ... undecided on these. see Event / Lathe for more detail          
          if options[:sequences]
            if target = event.target_for_origin(current_state)
              ts << binding.transition([event,target], *args) unless options[:cyclic]
            end
          end

          # build a list of transitions from the possible events and their targets
          if event.targets
            next unless event.target if options[:simple]
            event.targets.flatten.each do |target|
              next if options[:target] and target != options[:target]
              t = Transition.new(binding, event, target, *args)
              ts << t if (t.valid? or !options[:valid])
            end
          end

        end
      end.flatten.extend(Result)
      
      if @args || @block
        @result.each do |t|
          t.apply!( &@block) if @block 
          t.args = @args     if @args
        end
      end
      
      @result
    end # result 

    # sanitizes / extracts destination for find.
    #
    # takes a single, simple (one target only) event,
    # or an array of [event, target],
    # or one of the above with symbols in place of the objects themselves.    
    def parse_destination(destination)
      event, target = destination

      unless event.is_a?(Event)
        event = binding.machine.events[event]
      end
      
      unless target.is_a?(State)
        target = binding.machine.states[target] rescue nil
      end
        
      raise ArgumentError.new( [event,target].inspect ) unless
        [[Event, State],[Event, NilClass]].include?( [event,target].map(&:class) )
      [event, target]
    end # parse_destination

  end
end
 