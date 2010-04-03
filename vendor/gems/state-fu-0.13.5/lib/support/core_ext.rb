# if ActiveSupport is absent, install a very small subset of it for
# some convenience methods
unless Object.const_defined?('ActiveSupport')  #:nodoc
  Dir[File.join(File.dirname( __FILE__), 'active_support_lite','**' )].sort.each do |lib|
    lib = File.expand_path lib
    next unless File.file?( lib )
    require lib
  end

  class Hash #:nodoc
    include ActiveSupport::CoreExtensions::Hash::Keys
  end
end

# ruby1.9 style symbol comparability for ruby1.8
if RUBY_VERSION < "1.9"
  class Symbol   #:nodoc
    unless instance_methods.include?(:'<=>')
      def <=> other
        self.to_s <=> other.to_s
      end
    end
  end
end

module ArrayToHash
  def to_h
    if RUBY_VERSION >= '1.8.7'
      Hash[self]
    else
      inject({}) { |h, a| h[a.first] = a.last; h }
    end
  end
end

class Array
  include ArrayToHash unless instance_methods.include?(:to_h)
end

class Object
  unless defined? instance_exec # 1.9
    module InstanceExecMethods #:nodoc:
    end
    include InstanceExecMethods

    # Evaluate the block with the given arguments within the context of
    # this object, so self is set to the method receiver.
    #
    # From Mauricio's http://eigenclass.org/hiki/bounded+space+instance_exec
    def instance_exec(*args, &block)
      begin
        old_critical, Thread.critical = Thread.critical, true
        n = 0
        n += 1 while respond_to?(method_name = "__instance_exec#{n}")
        InstanceExecMethods.module_eval { define_method(method_name, &block) }
      ensure
        Thread.critical = old_critical
      end

      begin
        send(method_name, *args)
      ensure
        InstanceExecMethods.module_eval { remove_method(method_name) } rescue nil
      end
    end
  end
end

