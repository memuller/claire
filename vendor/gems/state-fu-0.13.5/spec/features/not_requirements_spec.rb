require File.expand_path("#{File.dirname(__FILE__)}/../helper")

module RequirementFeatureHelper

  def valid_password?
    !! valid_password
  end
end

describe "requirements" do

  before(:all) do
    reset!
    make_pristine_class('Klass')
    
    Klass.class_eval do
      attr_accessor :valid_password
      attr_accessor :account_expired
      
      def account_expired?
        !! account_expired
      end      
    end
    
    @machine = StateFu::Machine.new do
      initial_state :guest

      define(:valid_password?) { !! valid_password }

      event :has_valid_password, :from => :anonymous, :to => :logged_in do
        requires :valid_password?
      end

      event :has_not_valid_password, :from => :anonymous, :to => :suspect do
        requires :not_valid_password?
      end

      event :has_no_valid_password, :from => :anonymous, :to => :suspect do
        requires :no_valid_password?
      end  
    end

    @machine.bind!(Klass, :default)
    @obj     = Klass.new
    @binding = @obj.state_fu
  end

  before :each do
    @obj.valid_password = true
    @obj.account_expired = false
  end

  it "should have methods ...." do
    @obj.should respond_to(:account_expired?)
    @machine.named_procs.keys.should include(:valid_password?)
  end
  
  it "should return the opposite of the requirement name without not_" do
    @obj.stfu.teleport! :anonymous
    @obj.valid_password = false
    @binding.can_has_valid_password?.should == false
    @binding.can_has_not_valid_password?.should == true
    @binding.can_has_no_valid_password?.should == true
    @obj.valid_password = true
    @binding.can_has_valid_password?.should == true
    @binding.can_has_not_valid_password?.should == false
    @binding.can_has_no_valid_password?.should == false
  end

  it "should call the method directly if one exists" do
    @obj.valid_password = true
    (class << @obj; self; end).class_eval do
      define_method( :no_valid_password? ) { true }
    end
    @binding.can_has_valid_password?.should == true
    @binding.can_has_not_valid_password?.should == false
    @binding.can_has_no_valid_password?.should == true
  end      

end
