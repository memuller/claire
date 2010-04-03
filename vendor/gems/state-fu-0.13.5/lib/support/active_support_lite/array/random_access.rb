module ActiveSupport #:nodoc
  module CoreExtensions #:nodoc
    module Array #:nodoc
      module RandomAccess
        # Returns a random element from the array.
        #:nodoc
        def rand
          self[Kernel.rand(length)]
        end
      end
    end
  end
end
