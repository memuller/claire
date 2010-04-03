module StateFu
  module Persistence
    class ActiveRecord < StateFu::Persistence::Base

      def self.prepare_field( klass, field_name )
        _field_name = field_name
        Logging.debug("Preparing ActiveRecord field #{klass}.#{field_name}")

        # this adds a before_save hook to ensure that the field is initialized 
        # (and the initial state set) before create.
        klass.send :before_validation_on_create, :state_fu!
                
        # it's usually a good idea to do this:
        # validates_presence_of _field_name
                
        klass.class_eval do
          # this is a hack to ensure that when you use the same field for the database
          # column and the machine name, you don't end up with an unserializable 
          # StateFu::Binding in record#changes() ...
          def attribute_change(column)
            change = super
            if self.class.respond_to?(:machines) && self.class.machines.keys.include?(column.to_sym) 
              change[1] = read_attribute(column)
            end
            change
          end                
        end
      end

      private

      # We already checked that they exist, or we'd be using the
      # Attribute version, so just do the simplest thing we can.

      def read_attribute
        Logging.debug "Read attribute #{field_name}, got #{object.send(:read_attribute,field_name)} for #{object.inspect}"
        object.send( :read_attribute, field_name )
      end

      def write_attribute( string_value )
        Logging.debug "Write attribute #{field_name} to #{string_value} for #{object.inspect}"
        object.send( :write_attribute, field_name, string_value )
      end

    end
  end
end
