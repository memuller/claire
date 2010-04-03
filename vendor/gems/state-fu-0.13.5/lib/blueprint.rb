module StateFu
  module Blueprint

    def self.load_yaml(yaml)
      hash = YAML.load(yaml) 
      returning Machine.new(hash[:options] || {}) do |machine|
        add_states machine, hash
        add_events machine, hash
        hash[:requirement_messages] &&
          hash[:requirement_messages].each { |k, v| machine.requirement_messages[k] = v } 
        hash[:initial_state] &&
          machine.initial_state = hash[:initial_state] 
        # TODO tools, helpers here
      end
    end
        
    def self.to_yaml(machine)
      to_hash(machine).to_yaml
    end
   
    private
    
    # serialization
    
    def self.to_hash(machine)
      raise TypeError unless machine.serializable?
      {
        :states  => machine.states.map{ |s| state s }, 
        :events  => machine.events.map{ |e| event e },        
        :options => machine.options,
        :helpers => machine.helpers,
        :tools   => machine.tools,
        :requirement_messages => machine.requirement_messages,
        :initial_state => machine.initial_state.name
      }.delete_if {|k, v| v == [] || v.nil?}
    end
    
    def self.state(state)
      {
        :name         => state.name,
        :hooks        => state.hooks.dup.delete_if {|k,v| v == []},
        :requirements => state.requirements,
        :options      => state.options
      }.delete_if {|k,v| v == [] || v == {}}
    end
    
    def self.event(event)
      {
        :name         => event.name,
        :origins      => event.origins.names,
        :targets      => event.targets.names,
        :hooks        => event.hooks.dup.delete_if {|k,v| v == []},
        :requirements => event.requirements,
        :options      => event.options
      }.delete_if {|k,v| v == [] || v == {}}
    end
    
    # deserialization
    
    def self.add_states(machine, hash)
      hash[:states].each do |h|
        s = State.new(machine, h[:name], h[:options] || {})
        # cheap hacks to get around the data structures used for hooks and requirements          
        h[:hooks].each { |k, hooks| hooks.each { |hook| s.hooks[k] << hook }} if h[:hooks]
        h[:requirements].each { |r| s.requirements << r } if h[:requirements]
        machine.states << s
      end        
    end
        
    def self.add_events(machine, hash)
      hash[:events].each do |h|          
        e = Event.new(machine, h[:name], h[:options] || {})
        e.origins = h[:origins]
        e.targets = h[:targets]
        # cheap hacks to get around the data structures used for hooks and requirements
        h[:hooks].each { |k, hooks| hooks.each { |hook| e.hooks[k] << hook }} if h[:hooks]
        h[:requirements].each { |r| e.requirements << r } if h[:requirements]
        machine.events << e
      end
    end
  end
end