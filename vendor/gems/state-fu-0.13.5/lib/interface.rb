module StateFu
  module Interface
    module SoftAlias

      def soft_alias(hash)
        existing_method_names = (self.instance_methods | self.protected_instance_methods | self.private_instance_methods).map(&:to_sym)
        hash.each do |original, aliases|
          aliases.
            reject { |a| existing_method_names.include?(a.to_sym) }.
            each { |a| alias_method a, original}
        end
      end      
    end

    module Aliases
      # define aliases that won't clobber existing methods - 
      # so we can be liberal with them.
      def self.extended(base)
        base.extend SoftAlias
        base.class_eval do
          # instance method aliases
          soft_alias :state_fu          => [:stfu, :fu, :stateful, :workflow, :engine, :machine, :context]
          soft_alias :state_fu_bindings => [:bindings, :workflows, :engines, :machines, :contexts]
          soft_alias :state_fu!         => [:stfu!, :initialize_machines!, :initialize_state!]
          class << self
            extend SoftAlias
            # class method aliases
            soft_alias :state_fu_machine       => [:stfu, :state_fu, :workflow, :stateful, :statefully, :state_machine, :engine]
            soft_alias :state_fu_machines      => [:stfus, :state_fus, :workflows, :engines]
          end
        end
      end
    end

    # Provides access to StateFu to your classes.  Plenty of aliases are
    # provided so you can use whatever makes sense to you.
    module ClassMethods

      # TODO:
      # take option :alias => false (disable aliases) or :alias
      # => :foo (add :foo as class & instance accessor methods)

      # Given no arguments, return the default machine (:state_fu) for the
      # class, creating it if it did not exist.
      #
      # Given a symbol, return the machine by that name, creating it
      # if it didn't exist, and definining it if a block is passed.
      #
      # Given a block, apply it to a StateFu::Lathe to define a
      # machine, and return it.
      #
      # This can be done multiple times; changes are cumulative.
      #
      # You can have as many machines as you like per class.
      #
      # Klass.machine            # the default machine named :om
      #                          # equivalent to Klass.machine(:om)
      # Klass.machine(:workflow) # another totally separate machine
      #
      # recognised options are:
      #  :field_name - specify the field to use for persistence.
      #  defaults to {machine_name}_field.
      #
      def state_fu_machine( *args, &block )
        options = args.extract_options!.symbolize_keys!
        name    = args[0] || DEFAULT
        StateFu::Machine.for_class( self, name, options, &block )
      end
      alias_method :machine, :state_fu_machine

      def state_fu_options
        @_state_fu_options ||= {}
      end

      def state_fu_machines
        @_state_fu_machines ||= {}
      end
      alias_method :machines, :state_fu_machines

    end

    # These methods grant access to StateFu::Binding objects, which
    # are bundles of context encapsulating a StateFu::Machine, an instance
    # of a class, and its current state in the machine.

    module InstanceMethods

      def state_fu_bindings
        @_state_fu_bindings ||= {}
      end

      # A StateFu::Binding comes into being when it is first referenced.
      #
      # This is the accessor method through which an object instance (or developer)
      # can access a StateFu::Machine, the object's current state, the
      # methods which trigger event transitions, etc.

      def state_fu_binding(name = DEFAULT)
        name = name.to_sym 
        if machine = self.class.state_fu_machines[name]
          state_fu_bindings[name] ||= StateFu::Binding.new( machine, self, name )
        else raise ArgumentError.new("No state machine called #{name} for #{self.class} #{self}")
        end
      end
      alias_method :state_fu, :state_fu_binding

      def current_state( name = DEFAULT )
        state_fu_binding(name).current_state
      end
      
      def next!(name = DEFAULT, *args, &block )
        state_fu_binding(name).next! *args, &block
      end
      alias_method :next_state!,           :next!
      alias_method :fire_next_transition!, :next!      

      # Instantiate bindings for all machines, which ensures that persistence
      # fields are intialized and event methods defined.
      # It's useful to call this before_create w/
      # ActiveRecord classes, as this will cause the database field
      # to be populated with the default state name.
      
      def state_fu!
        MethodFactory.define_singleton_method(self, :initialize_state_fu!) { true }
        self.class.state_fu_machines.keys.map { |n| state_fu_binding( n ) }
      end

    end # ClassMethods
  end # Interface
end # StateFu
