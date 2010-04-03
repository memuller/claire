module StateFu
  module Persistence
    class Attribute < StateFu::Persistence::Base

      def self.prepare_field( klass, field_name )
        # ensure getter exists
        unless klass.instance_methods.map(&:to_sym).include?( field_name.to_sym )
          Logging.debug "Adding attr_reader :#{field_name} for #{klass}"
          _field_name = field_name
          klass.class_eval do
            private
            attr_reader _field_name
          end
        end

        # ensure setter exists
        unless klass.instance_methods.map(&:to_sym).include?( :"#{field_name}=" )
          Logging.debug "Adding attr_writer :#{field_name}= for #{klass}"
          _field_name = field_name
          klass.class_eval do
            private
            attr_writer _field_name
          end
        end
      end

  def b; binding; end
      private

      # Read / write our strings to a plain old instance variable
      # Define it if it doesn't exist the first time we go to read it

      def read_attribute
        string = object.send( field_name )
        Logging.debug "Read attribute #{field_name}, got #{string.inspect} for #{object.inspect}"
        string
      end

      def write_attribute( string_value )
        writer_method = "#{field_name}="
        Logging.debug "Writing attribute #{field_name} -> #{string_value.inspect} for #{object.inspect}"
        object.send( writer_method, string_value )
      end

    end
  end
end
