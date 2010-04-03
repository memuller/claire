module StateFu

  # the persistence module has a few simple tests which help decide which
  # persistence mechanism to use

  # TODO add event hooks (on_change etc) ...
  # after benchmarking

  # To create your own custom persistence mechanism,
  # subclass StateFu::Persistence::Base
  # and define prepare_field, read_attribute and write_attribute:


  #  class StateFu::Persistence::MagneticCarpet < StateFu::Persistence::Base
  #    def prepare_field
  #
  #
  #    def read_attribute
  #      object.send "magnetised_#{field_name}"
  #    end
  #
  #    def write_attribute( string_value )
  #      Logging.debug "magnetising ( #{field_name} => #{string_value} on #{object.inspect}"
  #      object.send "magnetised_#{field_name}=", string_value
  #    end
  #  end

  module Persistence
    DEFAULT_SUFFIX    = '_field'
    @@class_for       = {}
    @@fields_prepared = {}

    #
    # Class Methods
    #

    def self.default_field_name( machine_name )
      machine_name == DEFAULT ? DEFAULT_FIELD : "#{machine_name.to_s.underscore.tr(' ','_')}#{DEFAULT_SUFFIX}"
    end

    # returns the appropriate persister class for the given class & field name.
    def self.class_for(klass, field_name)
      raise ArgumentError if [klass, field_name].any?(&:nil?)
      @@class_for[klass] ||= {}
      @@class_for[klass][field_name] ||=
        if active_record_column?( klass, field_name )
          self::ActiveRecord
        elsif relaxdb_document_property?( klass, field_name )
          self::RelaxDB
        else
          self::Attribute
        end
    end

    def self.for_class(klass, binding, field_name)
      persister_class = class_for klass, field_name
      prepare_field( klass, field_name, persister_class)
      returning persister_class.new( binding, field_name ) do |persister|
        Logging.debug( "#{persister_class}: method #{binding.method_name} as field #{persister.field_name}" )
      end
    end

    def self.for_instance(binding, field_name)
      metaclass = class << binding.object; self; end
      for_class( metaclass, binding, field_name )
    end

    # returns a new persister appropriate to the given binding and field_name
    # also ensures the persister class method :prepare_field has been called
    # once for the given class & field name so the field can be set up; eg an
    # attr_accessor or a before_save hook defined
    def self.for(binding)
      field_name = binding.field_name.to_sym
      if binding.singleton?
        for_instance( binding, field_name )
      else
        for_class( binding.target, binding, field_name )
      end
    end

    # ensures that <persister_class>.prepare_field is called only once
    def self.prepare_field(klass, field_name, persister_class=nil)
      @@fields_prepared[klass] ||= []
      unless @@fields_prepared[klass].include?(field_name)
        persister_class ||= class_for(klass, field_name)
        persister_class.prepare_field( klass, field_name )
        @@fields_prepared[klass] << field_name
      end
    end

    #
    # Heuristics - simple test methods to determine which persister to use
    #

    # checks to see if the field_name for persistence is a
    # RelaxDB attribute.
    # Safe to use (skipped) if RelaxDB is not included.
    def self.relaxdb_document_property?(klass, field_name)
      Object.const_defined?('RelaxDB') &&
        klass.ancestors.include?( ::RelaxDB::Document ) &&
        klass.properties.map(&:to_s).include?(field_name.to_s)
    end

    # checks to see if the field_name for persistence is an
    # ActiveRecord column.
    # Safe to use (skipped) if ActiveRecord is not included.
    def self.active_record_column?(klass, field_name)
      Object.const_defined?("ActiveRecord") &&
        ::ActiveRecord.const_defined?("Base") &&
        klass.ancestors.include?(::ActiveRecord::Base) &&
        klass.table_exists? &&
        klass.columns.map(&:name).include?(field_name.to_s)
    end

  end
end
