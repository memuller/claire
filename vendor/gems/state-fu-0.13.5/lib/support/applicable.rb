module StateFu
  module Applicable
    module InstanceMethods

      # if given a hash of options (or a splatted arglist containing
      # one), merge them into @options. If given a block, eval it
      # (yielding self if the block expects it)

      def apply!( _options=nil, &block )
        if _options.is_a?(Array)
          _options  = _options.dup.extract_options!.symbolize_keys
        else          
          _options ||= {}
          _options = _options.symbolize_keys!
        end

        @options = @options.nil?? _options : @options.merge(_options)
        returning self do
          if block_given?
            case block.arity.abs
            when 1, -1
              instance_exec self, &block
            when 0
              instance_exec &block
            else
              raise ArgumentError, "Your block wants too many arguments!"
            end
          end
        end
      end
    end

    module ClassMethods
    end

    def self.included( mod )
      mod.send( :include, InstanceMethods )
      mod.extend( ClassMethods )
    end
  end
end
