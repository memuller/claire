module StateFu

  # Stuff shared between StateArray and EventArray
  module ArrayWithSymbolAccessor

    # Pass a symbol to the array and get the object with that .name
    # [<Foo @name=:bob>][:bob]
    # => <Foo @name=:bob>

    def []( idx )
      begin
        super( idx )
      rescue TypeError => e
        if idx.respond_to?(:to_sym)
          self.detect { |i| i == idx || i.respond_to?(:name) && i.name == idx.to_sym }
        else
          raise e
        end
      end
    end

    # so we can go Machine.states.names
    # mildly helpful with irb + readline
    def names
      map(&:name)
    end

    # SPECME
    def except *syms
      reject {|el| syms.flatten.compact.map(&:to_sym).include?(el.to_sym) } #.extend ArrayWithSymbolAccessor
    end

    def only *syms
      select {|el| syms.flatten.compact.map(&:to_sym).include?(el.to_sym) } #.extend ArrayWithSymbolAccessor
    end
      
    def all
      self
    end
    
    def rand
      self.rand
    end

  end

  module TransitionArgsArray
    attr_reader :transition
    
    def init(t)
      @transition = t
      self
    end
    
    delegate :options, :to => :transition
    delegate :binding, :to => :transition
    delegate :machine, :to => :transition
    delegate :origin,  :to => :transition
    delegate :target,  :to => :transition                

    def []( index )
      begin
        super( index )
      rescue TypeError
        options[index]
      end
    end
    
  end 
  
  # Array extender. Used by Machine to keep a list of states.
  module StateArray
    include ArrayWithSymbolAccessor

    # is there exactly one possible event to fire, with a single
    # target event?
    def next?
      raise NotImplementedError
    end

    # if next?, return the state
    def next
      raise NotImplementedError
    end

  end

  # Array extender. Used by Machine to keep a list of events.
  module EventArray
    include ArrayWithSymbolAccessor

    # return all events transitioning from the given state
    def from( origin )
      select { |e| e.respond_to?(:from?) && e.from?( origin ) }
    end

    # return all events transitioning to the given state
    def to( target )
      select { |e| e.respond_to?(:to?) && e.to?( target ) }
    end

    # is there exactly one possible event to fire, with a single
    # target event?
    def next?
      raise NotImplementedError
    end

    # if next?, return the event
    def next
      raise NotImplementedError
    end

  end

  module ModuleRefArray
    def modules
      self.map do |h|
        case h
        when String, Symbol
          mod_name = h.to_s.split('/').inject(Object) do |mod, part|
            mod = mod.const_get( part.camelize )
          end
        when Module
          h
        else
          raise ArgumentError.new( h.class.inspect )
        end
      end
    end # modules

    def inject_into( obj )
      metaclass = class << obj; self; end
      mods = self.modules()
      metaclass.class_eval do
        mods.each do |mod|
          include( mod )
        end
      end
    end
  end

  # Array extender. Used by Machine to keep a list of helpers to mix into
  # context objects.
  module HelperArray
    include ModuleRefArray
  end

  module ToolArray
    include ModuleRefArray
  end


  module MessageArray
    def strings
      select { |m| m.is_a? String }
    end

    def symbols
      select { |m| m.is_a? Symbol }
    end
  end

  # Extend an Array with this. It's a fairly compact implementation,
  # though it won't be super fast with lots of elements.
  # items. Internally objects are stored as a list of
  # [:key, 'value'] pairs.
  module OrderedHash
    # if given a symbol / string, treat it as a key
    def []( index )
      begin
        super( index )
      rescue TypeError
        ( x = self.detect { |i| i.first == index }) && x[1]
      end
    end

    # hash-style setter
    def []=( index, value )
      begin
        super( index, value )
      rescue TypeError
        ( x = self.detect { |i| i.first == index }) ?
        x[1] = value : self << [ index, value ].extend( OrderedHash )
      end
    end

    # poor man's Hash.keys
    def keys
      map(&:first)
    end

    # poor man's Hash.values
    def values
      map(&:last)
    end
  end  # OrderedHash
end
