module StateFu

  class MagicMethodError < NoMethodError
  end

  class Error < ::StandardError
    attr_reader :binding, :options

    def initialize binding, message=nil, options={}
      @binding = binding
      @options = options
      super message
    end
    
  end

  class TransitionNotFound < Error
    attr_reader :valid_transitions
    attr_reader :valid_destinations    
    DEFAULT_MESSAGE = "Transition could not be determined"
    
    def initialize(binding, valid_transitions, message=DEFAULT_MESSAGE, options={})
      @valid_transitions  = valid_transitions
      @valid_destinations = valid_transitions.map(&:destination)
      super(binding, message, options)
    end

    def inspect
      "<#{self.class.to_s} #{message} available=[#{valid_destinations.inspect}]>"
    end
    
  end
  
  class TransitionError < Error
    # TODO default message
    attr_reader :transition

    def initialize transition, message=nil, options={}
      # raise caller.inspect unless transition.is_a?(Transition)
      @transition = transition 
      super transition.binding, message, options
    end

    delegate :origin, :to => :transition
    delegate :target, :to => :transition
    delegate :event,  :to => :transition    
    delegate :args,   :to => :transition    

    # TODO capture these on initialization
    delegate :unmet_requirements,         :to => :transition        
    delegate :unmet_requirement_messages, :to => :transition            
    delegate :requirement_errors,         :to => :transition            

    def inspect
      origin_name = origin && origin.name
      target_name = target && target.name
      event_name  = event  && event.name  
      "<#{self.class.to_s} #{message} #{origin_name.inspect}=[#{event_name.inspect}]=>#{target_name.inspect}>"
    end
  end

  class UnknownTarget < TransitionError
  end

  class TransitionAlreadyFired < TransitionError
  end
  
  class RequirementError < TransitionError
    include Enumerable 

    delegate :each,   :to => :to_h
    delegate :length, :to => :to_h
    delegate :empty?, :to => :to_h
        
    def to_a
      unmet_requirement_messages
    end
    
    def to_h
      requirement_errors
    end
    
    def to_s
      inspect
    end
    
    def inspect
      "<#{self.class.to_s}::#{__id__} :#{transition.origin.to_sym}-[#{transition.event.to_sym}]->:#{transition.target.to_sym} unmet_requirements=#{to_a.inspect}>"
    end
  end

  class TransitionHalted < TransitionError
  end

  # deprecated?
  # class Invalid Transition < TransitionError

  class IllegalTransition < TransitionError
    attr_reader :legal_transitions

    def initialize transition, message=nil, valid_transitions=nil, options={}
      @legal_transitions = valid_transitions
      super transition, message, options
    end    
  end
end
