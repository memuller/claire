module StateFu
  #
  # class that handles executing stuff in the context of your 'object'
  #
    
  class Executioner

    attr_reader :transition, :object

    def initialize transition, &block
      @transition = transition
      @object     = transition.object
      self
    end

    def evaluate method_name_or_proc
      args = [transition, transition.arguments]
      evaluate_with_arguments(method_name_or_proc, *args)
    end
    
    private
    
    def evaluate_with_arguments method_name_or_proc, *arguments      
      if method_name_or_proc.is_a?(Proc) && 
        meth = method_name_or_proc 
        # got a proc
      elsif meth = transition.machine.named_procs[method_name_or_proc] 
        # got a named proc belonging to the machine
      elsif object.__send__(:respond_to?, method_name_or_proc, true) && 
        meth = object.__send__(:method, method_name_or_proc)
        # got the name of a method on 'object'
      elsif method_name_or_proc.to_s =~ /^not?_(.*)$/
        # special case: given a method name prefixed with no_ or not_ 
        # return the boolean opposite of its evaluation result
        return !( evaluate_with_arguments $1.to_sym, *arguments )
      else
        raise NoMethodError.new( "undefined method_name `#{method_name_or_proc.to_s}' for \"#{object}\":#{object.class.to_s}" )
      end      

      if arguments.length < meth.arity.abs && meth.arity != -1
        # ensure we don't have too few arguments
        raise ArgumentError.new([meth.arity, arguments.length].inspect) 
      else
        # ensure we don't pass too many arguments
        arguments = arguments[0, meth.arity.abs]
      end
      
      # execute it!
      object.__send__(:instance_exec, *arguments, &meth)
    end
    
  end
end
