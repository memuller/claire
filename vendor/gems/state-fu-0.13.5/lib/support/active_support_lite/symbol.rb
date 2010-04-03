unless :to_proc.respond_to?(:to_proc)  #:nodoc:all
  class Symbol
    # Turns the symbol into a simple proc, which is especially useful for enumerations. Examples:
    #
    #   # The same as people.collect { |p| p.name }
    #   people.collect(&:name)
    #
    #   # The same as people.select { |p| p.manager? }.collect { |p| p.salary }
    #   people.select(&:manager?).collect(&:salary)
     #:nodoc
    def to_proc
      Proc.new { |*args| args.shift.__send__(self, *args) }
    end
  end
end

