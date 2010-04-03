module MongoMapper
  module RailsCompatibility
    module EmbeddedDocument
      def self.included(model)
        model.class_eval do
          extend ClassMethods
          
          alias_method :new_record?, :new?
        end

        class << model
          alias has_many many
          alias has_one one
        end
      end

      module ClassMethods
        def column_names
          keys.keys
        end
        
        def human_name
          self.name.demodulize.titleize
        end
      end
    end
  end
end