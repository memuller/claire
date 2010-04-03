module StateFu
  # This class is responsible for defining methods at runtime.
  #
  # TODO: all events, simple or complex, should get the same method signature
  # simple events will be called as:  event_name! nil,    *args
  # complex events will be called as: event_name! :state, *args

  class MethodFactory
    attr_accessor :method_definitions
    attr_reader   :binding, :machine

    # An instance of MethodFactory is created to define methods on a specific StateFu::Binding, and
    # on the object / class it is bound to.

    def initialize(_binding)
      @binding            = _binding
      @machine            = binding.machine
      @method_definitions = MethodFactory.method_definitions_for(@machine, @binding.method_name)
      self
    end

    def self.method_definitions_for(machine, name)
      returning Hash.new do |method_definitions|
        simple_events, complex_events = machine.events.partition &:simple?

        # simple event methods
        # all arguments are passed into the transition / transition query

        simple_events.each do |event|
          method_definitions["#{event.name}"]      = lambda do |*args|
            state_fu(name).find_transition(event, event.target, *args)
          end

          method_definitions["can_#{event.name}?"] = lambda do |*args|
            state_fu(name).can_transition?(event, event.target, *args)
          end

          method_definitions["#{event.name}!"]     = lambda do |*args|
            state_fu(name).fire_transition!(event, event.target, *args)
          end
        end

        # "complex" event methods (for events with more than one possible target)
        # the first argument is the target state
        # any remaining arguments are passed into the transition / transition query

        # object.event_name [:target], *arguments
        #
        # returns a new transition. Will raise an IllegalTransition if
        # it is not given arguments which result in a valid combination
        # of event and target state being deducted.
        #
        # object.event_name [nil] suffices if the event has only one valid
        # target (ie only one transition which would not raise a
        # RequirementError if fired)

        # object.event_name! [:target], *arguments
        #
        # as per the method above, except that it also fires the event

        # object.can_<event_name>? [:target], *arguments
        #
        # tests that calling event_name or event_name! would not raise an error
        # ie, the transition is legal and is valid with the arguments supplied

        complex_events.each do |event|
          method_definitions["#{event.name}"]      = lambda do |target, *args|
            state_fu(name).find_transition(event, target, *args)
          end

          method_definitions["can_#{event.name}?"] = lambda do |target, *args|
            begin
              t = state_fu(name).find_transition(event, target, *args)
              t.valid?
            rescue IllegalTransition
              false
            end
          end

          method_definitions["#{event.name}!"]     = lambda do |target, *args|
            state_fu(name).fire_transition!(event, target, *args)
          end
        end

        # methods for a "complex" event with a specific target
        # eg progress_to_deleted!(*args)
        # is equivalent to progress!(:deleted, *args)
        
        (simple_events + complex_events).each do |event|
          event.targets.each do |target|
            method_definitions["#{event.name}_to_#{target.name}"]      = lambda do |*args|
              state_fu(name).find_transition(event, target, *args)
            end

            method_definitions["can_#{event.name}_to_#{target.name}?"] = lambda do |*args|
              state_fu(name).can_transition?(event, target, *args)
            end

            method_definitions["#{event.name}_to_#{target.name}!"]     = lambda do |*args|
              state_fu(name).fire_transition!(event, target, *args)
            end
          end unless event.targets.nil?
        end
        
        # sugar: query methods for determining the current state

        machine.states.each do |state|
          method_definitions["#{state.name}?"] = lambda do
            state_fu(name).current_state == state
          end
        end
      end
    end

    #
    # Class Methods
    #

    # This should be called once per machine bound to a class.
    # It defines methods for the machine as standard methods, 
    # if the machine is the default machine or the options passed to the machine include 
    # :define_methods => true .
    #
    # Note this happens when a machine is first bound to the class,
    # not when StateFu is included.

    def self.prepare_class_machine(klass, machine, name, options)
      return unless options[:define_methods]

      method_definitions_for(machine, name).each do |method_name, block|
        unless klass.respond_to? method_name, true
          klass.class_eval do
            define_method method_name, &block
          end
        end
      end

    end # prepare_class

    # Define the same helper methods on the StateFu::Binding and its
    # object.  Any existing methods will not be tampered with, but a
    # warning will be issued in the logs if any methods cannot be defined.
    def install!
      define_event_methods_on @binding
      define_event_methods_on @binding.object if @binding.options[:define_methods] && @binding.options[:singleton]
    end

    private 
    
    #
    # For each event, on the given object, define three methods.
    # - The first method is the same as the event name.
    #   Returns a new, unfired transition object.
    # - The second method has a "?" suffix.
    #   Returns true if the event can be fired.
    # - The third method has a "!" suffix.
    #   Creates a new Transition, fires and returns it once complete.
    #
    # The arguments expected depend on whether the event is "simple" - ie,
    # has only one possible target state.
    #
    # All simple event methods pass their entire argument list
    # directly to transition.  These arguments can be accessed inside
    # event hooks, requirements, etc by calling Transition#args.
    #
    # All complex event methods require their first argument to be a
    # Symbol containing a valid target State's name, or the State
    # itself.  The remaining arguments are passed into the transition,
    # as with simple event methods.
    #
    def define_event_methods_on(obj)
      method_definitions.each do |method_name, method_body|
        define_singleton_method obj, method_name, &method_body
      end
    end # define_event_methods_on

    def define_singleton_method(object, method_name, &block)
      MethodFactory.define_singleton_method object, method_name, &block
    end

    # define a a method on the metaclass of the given object. The
    # resulting "singleton method" will be unique to that instance,
    # not shared by other instances of its class.
    #
    # This allows us to embed a reference to the instance's unique
    # binding in the new method.
    #
    # existing methods will never be overwritten.

    def self.define_singleton_method(object, method_name, options={}, &block)
      if object.respond_to? method_name, true
        msg = !options[:force]
        Logging.info "Existing method #{method(method_name) rescue [method_name].inspect} "\
          "for #{object.class} #{object} "\
          "#{options[:force] ? 'WILL' : 'won\'t'} "\
          "be overwritten."
      else
        metaclass = class << object; self; end
        metaclass.class_eval do
          define_method method_name, &block
        end
      end
    end
    alias_method :define_singleton_method, :define_singleton_method

  end # class MethodFactory
end # module StateFu


