module StateFu

  class InvalidStateName < Exception
  end

  module Persistence
    class Base

      attr_reader :binding, :field_name, :current_state

      # define this method in subclasses to do any preparation
      def self.prepare_field( klass, field_name )
        Logging.warn("Abstract method in #{self}.prepare_field called. Override me!")
      end

      def initialize( binding, field_name )

        @binding       = binding
        @field_name    = field_name
        @current_state = find_current_state()

        if current_state.nil?
          Logging.warn("undefined state for binding #{binding} on #{object} with field_name #{field_name.inspect}")
          Logging.warn("Machine for #{object} has no states: #{machine}") if machine.states.empty?
        else
          persist!
          Logging.debug("#{object} resumes #{binding.method_name} at #{current_state.name}")
        end
      end

      def find_current_state
        string = read_attribute()
        if string.blank?
          machine.initial_state
        else
          state_name = string.to_sym
          state      = machine.states[ state_name ] || raise( StateFu::InvalidStateName, string )
        end
      end

      def reload
        @current_state = find_current_state()
      end

      def machine
        binding.machine
      end

      def object
        binding.object
      end

      def klass
        binding.target
      end

      def current_state=( state )
        raise(ArgumentError, state.inspect) unless state.is_a?(StateFu::State)
        @current_state = state
        persist!
      end

      def value()
        @current_state && @current_state.name.to_s
      end

      def persist!
        write_attribute( value() )
      end

      private

      def read_attribute
        raise "Abstract method! override me"
      end

      def write_attribute( string_value )
        raise "Abstract method! override me"
      end

    end
  end
end

