module StateFu
  # the abstract superclass of State & Event
  # defines behaviours shared by both classes
  class Sprocket 
    include Applicable # define apply!
    include HasOptions
    
    attr_reader :machine, :name, :hooks

    def initialize(machine, name, options={})
      @machine = machine
      @name    = name.to_sym
      @options = options.symbolize_keys!
      @hooks   = StateFu::Hooks.for( self )
    end

    # sneaky way to make some comparisons / duck typing a bit cleaner
    alias_method :to_sym,  :name

    def add_hook slot, name, value
      @hooks[slot.to_sym] << [name.to_sym, value]
    end

    # yields a lathe for self; useful for updating machine definitions on the fly
    def lathe(options={}, &block)
      StateFu::Lathe.new( machine, self, options, &block )
    end

    def deep_copy
      raise NotImeplementedError # abstract
    end

    def to_s
      "#<#{self.class}::#{self.object_id} @name=#{name.inspect}>"
    end

    # allows state == <name> || event == <name> to return true
    def == other
      if other.is_a?(Symbol) 
        self.name == other
      else
        super other
      end
    end 

    # allows case equality tests against the state/event's name
    # eg
    # case state
    # when :new
    #   ...
    # end
    def === other
      self.to_sym === other.to_sym || super(other)
    end
    
    def serializable?
      !hooks.values.flatten.map(&:class).include?(Proc) && !!(options.to_yaml rescue false)
    end
    
  end
end

