require File.expand_path("#{File.dirname(__FILE__)}/../helper")

describe "a RelaxDB::Document's persister" do

  include MySpecHelper
  before(:all) do
    prepare_relaxdb()
  end

  before(:each) do
    if skip_slow_specs? 
      skip_slow_specs and return false
    end
    skip_unless_relaxdb()
    reset!
    make_pristine_class( 'ExampleDoc', RelaxDB::Document )
  end

  it "should be a subclass of RelaxDB::Document" do
    ExampleDoc.superclass.should == RelaxDB::Document
  end

  describe "when no machine is defined" do
  end

  describe "when the :field_name is a RelaxDB property" do
    before do
      ExampleDoc.class_eval do
        property :property_field
        state_fu_machine :field_name => "property_field" do
          # ...
        end
      end
      @obj = ExampleDoc.new
    end

    it "should add a relaxdb persister" do
      @obj.state_fu.persister.class.should == StateFu::Persistence::RelaxDB
    end
  end

  describe "when the :field_name is not a RelaxDB property" do
    before do
      ExampleDoc.class_eval do
        state_fu_machine :field_name => "not_a_property" do
          # ...
        end
      end
      @obj = ExampleDoc.new
    end
    it "should add an attribute-based persister" do
      @obj.state_fu.persister.class.should == StateFu::Persistence::Attribute
    end
  end
end

describe StateFu::Persistence::RelaxDB do
  before(:all) do
    prepare_relaxdb()
  end

  include MySpecHelper
  describe "a RelaxDB::Document with a simple machine" do
    before do
      skip_unless_relaxdb()
      reset!
      make_pristine_class( 'ExampleDoc', RelaxDB::Document )
      ExampleDoc.class_eval do
        property :state_fu_field
        state_fu_machine do
          state :hungry do
            event :eat, :to => :satiated
          end
        end # machine
      end # class_eval
      @obj = ExampleDoc.new
    end # before

    it "should update the property on transition acceptance" do
      @obj.state_fu.should == :hungry
      t = @obj.eat!
      t.should be_accepted
      @obj.state_fu.should == :satiated
      @obj.send(:state_fu_field).should == 'satiated'
    end

    it "should persist the current state of the machine to the database" do
      @obj.state_fu.should == :hungry
      @obj.eat!
      @obj.state_fu.should == :satiated
      @obj.save!
      @obj2 = RelaxDB.load( @obj._id )
      @obj2.state_fu.should == :satiated
    end

  end
end
