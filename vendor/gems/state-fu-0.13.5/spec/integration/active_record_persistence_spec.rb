require File.expand_path("#{File.dirname(__FILE__)}/../helper")

describe "an ActiveRecord model with StateFu included:" do

  include MySpecHelper

  before(:all) do
    reset!
    prepare_active_record() do
      def self.up
        create_table :example_records do |t|
          t.string :name,           :null => false
          t.string :state_fu_field, :null => false
          t.string :description
          t.string :status
          t.timestamps
        end
      end
    end

    # class ExampleRecord < ActiveRecord::Base
    make_pristine_class( 'ExampleRecord', ActiveRecord::Base )
    ExampleRecord.class_eval do
      validates_presence_of :name
    end
    # end class ExampleRecord
  end

  describe 'a machine with the same name as the database field' do
    before do
      make_pristine_class( 'IdentityCrisis', ActiveRecord::Base )
      IdentityCrisis.class_eval do
        set_table_name 'example_records'
        validates_presence_of :name
        machine(:state_fu_field, :field_name => :state_fu_field) do
          connect :a, :b, :c
        end
      end      
    end
    
    it 'should not include a StateFu::Binding in record#changes' do
      record = IdentityCrisis.new :name => 'coexisting field and machine name'
      record.save!
      record.state_fu_field.next!      
      record.changes['state_fu_field'].last.class.should == String
    end
  end

  it "should be a subclass of ActiveRecord::Base" do
    ExampleRecord.superclass.should == ActiveRecord::Base
  end

  describe "when the ActiveRecord model has no table yet (eg before migrations)" do
    before do
      make_pristine_class('TableMissingClass', ActiveRecord::Base )
      TableMissingClass.class_eval do
        state_fu_machine() { }
      end
    end

    it "should not raise an error when the persister is instantiated" do
      lambda { TableMissingClass.columns }.should raise_error
      lambda { TableMissingClass.state_fu_machine }.should_not raise_error
    end

  end
  describe "when the default machine is defined with no field_name specified" do
    before do
      ExampleRecord.class_eval do
        state_fu_machine do
          state :initial do
            # an after transition hook saves the record
            event( :change, :to => :final ) { after :save! }
          end
        end
      end
      @ex = ExampleRecord.new( :name => "exemplar" )
    end # before

    it "should have an active_record string column 'state_fu_field' " do
      col = ExampleRecord.columns.detect {|c| c.name == "state_fu_field" }
      col.type.should == :string
    end

    describe "calling :save! via an event's after hook" do
      it "should save the record with the new state persisted via the DB" do
        @ex.change!
        @ex.state_fu.name.should == :final
        @ex.state_fu_field.should == 'final'
        @ex.reload
        @ex.state_fu_field.should == 'final'
        @ex.state_fu.name.should == :final
      end
    end

    describe "StateFu::Persistence.active_record_column?" do
      it "should return true for ExampleRecord, :state_fu_field" do
        StateFu::Persistence.active_record_column?( ExampleRecord, :state_fu_field ).should == true
      end

      it "should return true for ExampleRecord, :status" do
        StateFu::Persistence.active_record_column?( ExampleRecord, :status ).should == true
      end

      it "should return false for ExampleRecord, :not_a_column" do
        StateFu::Persistence.active_record_column?( ExampleRecord, :not_a_column ).should == false
      end

      it "should not clobber activerecord accessors" do
        @ex.noodle! rescue nil
        @ex.description.should be_nil
        @ex.description= 'foo'
        @ex.description.should == 'foo'
      end

      it "should have an active_record string column 'state_fu_field' " do
        col = ExampleRecord.columns.detect {|c| c.name == "state_fu_field" }
        col.type.should == :string
      end
    end

    it "should have an active_record persister with the default field_name 'state_fu_field' " do
      @ex.state_fu
      @ex.state_fu.should be_kind_of( StateFu::Binding )
      @ex.state_fu.persister.should be_kind_of( StateFu::Persistence::ActiveRecord )
      @ex.state_fu.persister.field_name.should == :state_fu_field
    end


    # this ensures state_fu initializes the field before create to
    # satisfy the not null constraint
    describe "automagic state_fu! before_save filter and validations" do

      it "should call state_fu! before a record is created"
      it "should call state_fu! before a record is updated"

      it "should create a record given only a name, with the field set to the initial state" do
        ex = ExampleRecord.new( :name => "exemplar" )
        ex.state_fu_field.should == nil
        ex.should be_valid
        ex.state_fu_field.should == 'initial'
        ex.save!
        ex.should_not be_new_record
        ex.state_fu_field.should == 'initial'
        ex.state_fu.state.name.should == :initial
      end

      it "should update the field after a transition is completed" do
        ex = ExampleRecord.create!( :name => "exemplar" )
        ex.state_fu.state.name.should == :initial
        ex.state_fu_field.should == 'initial'
        t = ex.state_fu.change!
        t.should be_accepted
        ex.state_fu.state.name.should == :final
        ex.state_fu_field.should == 'final'
        ex.attributes['state_fu_field'].should == 'final'
        ex.save!
      end

      describe "a saved record whose state is not the default" do
        before do
          @r = ExampleRecord.create!( :name => "exemplar" )
          @r.change!
          @r.state_fu_field.should == 'final'
          @r.save!
        end

        it "should be reconstituted with the correct state" do
          r = ExampleRecord.find( @r.id )
          r.state_fu.should be_kind_of( StateFu::Binding )
          r.state_fu.current_state.should be_kind_of( StateFu::State )
          r.state_fu.current_state.should == ExampleRecord.state_fu_machine.states[:final]
        end
      end # saved record after transition

      describe "when a second machine named :status is defined with :field_name => 'status'" do
        before do
          ExampleRecord.state_fu_machine(:status, :field_name => 'status') do
            event( :go, :from => :initial, :to => :final )
          end
          @ex = ExampleRecord.new()
        end

        it "should have a binding for .status" do
          @ex.status.should be_kind_of( StateFu::Binding )
        end

        it "should have an ActiveRecord persister with the field_name :status" do
          @ex.status.persister.should be_kind_of( StateFu::Persistence::ActiveRecord )
          @ex.status.persister.field_name.should == :status
        end

        it "should have a value of nil for the status field before state_fu is called" do
          @ex.read_attribute('status').should be_nil
        end

        it "should have the ActiveRecord setter method .status=" do
          @ex.status= 'damp'
          @ex.read_attribute(:status).should == 'damp'
        end

        it "should raise StateFu::InvalidState if the status field is set to a bad value and .status is called" do
          @ex.status= 'damp'
          lambda { @ex.status }.should raise_error( StateFu::InvalidStateName )
        end
      end # second machine
      
      describe "coexisting with an attribute-backed machine" do
        it "should get along merrily" do
          ExampleRecord.machine(:temporary, :field_name => 'temp') do
            state :new
          end
          @ex = ExampleRecord.new()
          @ex.temporary.should == :new
          @ex.instance_variable_get("@temp").should == 'new'
          @ex.temporary.persister.class.should == StateFu::Persistence::Attribute
        end
      end
      
    end 
  end   
end     
