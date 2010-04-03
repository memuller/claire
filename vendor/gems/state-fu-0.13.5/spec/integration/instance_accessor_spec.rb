require File.expand_path("#{File.dirname(__FILE__)}/../helper")

##
##
##

describe "An instance of Klass with StateFu included:" do
  include MySpecHelper
  before(:each) do
    make_pristine_class 'Klass'
    @k = Klass.new()
  end

  describe "when no machine is defined" do
    it "should raise an ArgumentError given .state_fu()" do
      lambda { @k.state_fu() }.should raise_error(ArgumentError)
    end

    it "should return {} given .bindings()" do
      @k.state_fu_bindings.should == {}
    end

    it "should return [] given .state_fu!()" do
      @k.state_fu!.should == []
    end 
  end # no machine

  describe "when an empty machine is defined for the class with the default name:" do
    before(:each) do
      Klass.state_fu_machine() {}
    end

    it "should return a StateFu::Binding given .state_fu()" do
      @k.state_fu_binding.should be_kind_of( StateFu::Binding )
    end

    describe "before a binding is instantiated by calling .state_fu() or .state_fu!" do
      it "should return {} given .bindings()" do
        @k.bindings.should == {}
      end
    end

    describe "after a binding is instantiated with .state_fu()" do
      before do
        @k.state_fu()
      end

      it "should return { :state_fu => <StateFu::Binding>} given .bindings()" do
        @k.bindings().length.should == 1
        @k.bindings().keys.should == [StateFu::DEFAULT]
        @k.bindings().values.first.should be_kind_of( StateFu::Binding )
      end
    end

    describe "after .state_fu!()" do
      it "should return { :state_fu => <StateFu::Binding>} given .bindings()" do
        @k.state_fu!()
        @k.bindings().length.should == 1
        @k.bindings().keys.should == [StateFu::DEFAULT]
        @k.bindings().values.first.should be_kind_of( StateFu::Binding )
      end
    end

    it "should return [<StateFu::Binding>] given .state_fu!()" do
      @k.state_fu!.length.should == 1
      @k.state_fu!.first.should be_kind_of( StateFu::Binding )
    end

    describe "when there is an empty machine called :two for the class" do
      before(:each) do
        Klass.state_fu_machine(:two) {}
      end

      it "should return the same Binding given .state_fu() and .state_fu(:state_fu)" do
        @k.state_fu().should be_kind_of( StateFu::Binding )
        @k.state_fu().should == @k.state_fu(StateFu::DEFAULT)
      end

      it "should return a StateFu::Binding for the machine called :two given .state_fu(:two)" do
        @k.state_fu(:two).should be_kind_of( StateFu::Binding )
        @k.state_fu(:two).should_not == @k.state_fu(StateFu::DEFAULT)
        @k.state_fu(:two).machine.should == Klass.state_fu_machine(:two)
      end

      it "should raise an ArgumentError when .state_fu() is called with the name of a machine which doesn't exist" do
        lambda { @k.state_fu(:hibiscus) }.should raise_error(ArgumentError)
      end

      it "should return an array of the two StateFu::Bindings given .state_fu!" do
        @k.state_fu!.should be_kind_of( Array )
        @k.state_fu!.length.should == 2
        @k.state_fu!.each { |m| m.should be_kind_of( StateFu::Binding ) }
        @k.state_fu!.map(&:method_name).sort_by(&:to_s).should == [StateFu::DEFAULT, :two]
      end
    end
  end
end
