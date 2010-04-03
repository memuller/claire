module StateFu
  class State < StateFu::Sprocket

    attr_reader :entry_requirements, :exit_requirements, :own_events
    alias_method :requirements, :entry_requirements
    
    def initialize(machine, name, options={})
      @entry_requirements = [].extend ArrayWithSymbolAccessor
      @exit_requirements  = [].extend ArrayWithSymbolAccessor
      @own_events         = [].extend EventArray
      super( machine, name, options )
    end

    def events
      machine.events.from(self)
    end

    def before?(other)
      machine.states.index(self) < machine.states.index(machine.states[other])
    end

    def after?(other)
      machine.states.index(self) > machine.states.index(machine.states[other])
    end

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
      unless entry_requirements.empty?
        s << " entry_requirements=#{entry_requirements.inspect}"
      end
      unless exit_requirements.empty?
        s << " exit_requirements=#{exit_requirements.inspect}"
      end
      s << ">"
      s
    end

  end
end
