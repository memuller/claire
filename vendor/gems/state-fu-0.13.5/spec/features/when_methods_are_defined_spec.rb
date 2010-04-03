require File.expand_path("#{File.dirname(__FILE__)}/../helper")

describe "instance methods defined for a class's machine," do
  before do
    make_pristine_class('Klass')
  end
  
  describe "for the default machine" do
    it "should define methods for states and events" do
      Klass.machine do
        event :go, :from => :a, :to => :b
      end
      instance = Klass.new
      instance.state_fu!
      instance.should respond_to(:a?)
      instance.should respond_to(:can_go?)      
    end   

    it "should not define methods given :define_methods => false" do
      Klass.machine :define_methods => false do
        event :go, :from => :a, :to => :b
      end
      instance = Klass.new
      instance.state_fu!
      instance.should_not respond_to(:a?)
      instance.should_not respond_to(:can_go?)
    end   
  end
  
  describe "for other machines" do
    it "should not define methods" do
      Klass.machine :other do
        event :go, :from => :a, :to => :b
      end
      instance = Klass.new
      instance.state_fu!
      instance.should_not respond_to(:a?)
      instance.should_not respond_to(:can_go?)      
    end
    
    it "should define methods given :define_methods => true" do
      Klass.machine :define_methods => true do
        event :go, :from => :a, :to => :b
      end
      instance = Klass.new
      instance.state_fu!
      instance.should respond_to(:a?)
      instance.should respond_to(:can_go?)
    end
  end
end


describe "instance methods when you #bind! a machine" do
  before do
    make_pristine_class('Klass')
    @machine = StateFu::Machine.new do
      state :hot
      state :cold
    end
  end
  
  describe "as the default machine," do
    describe "the default behaviour" do
      before do
        @machine.bind! Klass, :default, :define_methods => true
      end

      it "defines methods" do
        instance = Klass.new
        instance.state_fu!
        instance.should respond_to(:hot?)      
      end
    end

    describe "when it is bound with :define_methods => false" do
      before do
        @machine.bind! Klass, :default, :define_methods => false
      end

      it "should not define methods" do
        instance = Klass.new
        instance.state_fu!
        instance.should_not respond_to(:hot?)      
      end
    end
  end

  describe "as another machine," do
    describe "the default behaviour" do
      before do
        @machine.bind! Klass, :temperature
      end

      it "should not define methods" do
        instance = Klass.new
        instance.state_fu!
        instance.should_not respond_to(:hot?)      
      end
    end

    describe "when it is bound with :define_methods => true" do
      before do
        @machine.bind! Klass, :temperature, :define_methods => true
      end

      it "should define methods" do
        instance = Klass.new
        instance.state_fu!
        instance.should respond_to(:hot?)      
      end
    end
  end
end 
