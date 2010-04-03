require File.expand_path("#{File.dirname(__FILE__)}/../helper")

describe "defining an alias for the default machine" do
  describe "with machine(:as => :status)" do
    before do
      make_pristine_class('Klass')
      Klass.machine :as => :status do
        state :active
      end
      @obj = Klass.new
    end

    it "should not prevent normal access through #state_fu" do
      @obj.state_fu.machine.should == Klass.machine
    end
    
    it "should not affect the internal name of the machine" do
      @obj.status.method_name.should == :default
    end
    
    it "should let you access the machine through #status" do
      @obj.status.should be_kind_of(StateFu::Binding)
      @obj.status.machine.should == Klass.machine
      @obj.status.current_state.should == :active
    end
    
  end
end

describe "defining an alias for a default singleton machine" do
  describe "with #bind! :default, :as => :alias" do
    before do
      make_pristine_class('Klass')
      @machine = StateFu::Machine.new do
        state :exemplary
      end
      @obj = Klass.new
      @machine.bind!( @obj, :default, :as => :example)
    end
    
    it "should work too" do
      @obj.example.machine.should == @machine
    end    
  end
end

