require File.expand_path("#{File.dirname(__FILE__)}/../helper")


##
##
##

describe "A pristine class Klass with StateFu included:" do
  include MySpecHelper
  before(:each) do
    make_pristine_class 'Klass'
  end

  it "should return a new Machine bound to the class given Klass.state_fu_machine()" do
    Klass.should respond_to(:state_fu_machine)
    Klass.state_fu_machine.should be_kind_of(StateFu::Machine)
    machine = Klass.state_fu_machine
    Klass.state_fu_machine.should == machine
  end

  it "should return {} given Klass.state_fu_machines" do
    Klass.should respond_to(:state_fu_machines)
    Klass.state_fu_machines.should == {}
  end

  ##
  ##
  ##

  describe "Having called Klass.state_fu_machine() with an empty block:" do
    before(:each) do
      Klass.state_fu_machine do
      end
    end

    it "should return a StateFu::Machine given Klass.state_fu_machine()" do
      Klass.should respond_to(:state_fu_machine)
      Klass.state_fu_machine.should_not be_nil
      Klass.state_fu_machine.should be_kind_of( StateFu::Machine )
    end

    it "should return { :default => <StateFu::Machine> } given Klass.state_fu_machines()" do
      Klass.should respond_to(:state_fu_machines)
      machines = Klass.state_fu_machines()
      machines.should be_kind_of(Hash)
      machines.should_not be_empty
      machines.length.should == 1
      machines.keys.should == [StateFu::DEFAULT]
      machines.values.first.should be_kind_of( StateFu::Machine )
    end

    describe "Having called Klass.state_fu_machine(:two) with an empty block:" do
      before(:each) do
        Klass.state_fu_machine(:two) do
        end
      end

      it "should return a StateFu::Machine given Klass.state_fu_machine(:two)" do
        Klass.should respond_to(:state_fu_machine)
        Klass.state_fu_machine(:two).should_not be_nil
        Klass.state_fu_machine(:two).should be_kind_of( StateFu::Machine )
      end

      it "should return a new Machine given Klass.state_fu_machine(:three)" do
        Klass.should respond_to(:state_fu_machine)
        Klass.state_fu_machine(:three).should be_kind_of( StateFu::Machine )
        three = Klass.state_fu_machine(:three)
        Klass.state_fu_machines[:three].should == three
        Klass.state_fu_machine(:three).should == three        
      end

      it "should return { :default => <StateFu::Machine>, :two => <StateFu::Machine> } given Klass.state_fu_machines()" do
        Klass.should respond_to(:state_fu_machines)
        machines = Klass.state_fu_machines()
        machines.should be_kind_of(Hash)
        machines.should_not be_empty
        machines.length.should == 2
        machines.keys.should include StateFu::DEFAULT
        machines.keys.should include :two
        machines.values.length.should == 2
        machines.values.each { |v| v.should be_kind_of( StateFu::Machine ) }
      end

      it "should return [DEFAULT, :two] give Klass.state_fu_machines.keys" do
        Klass.should respond_to(:state_fu_machines)
        Klass.state_fu_machines.keys.should =~ [StateFu::DEFAULT, :two]
      end
    end

    describe "An empty class Child which inherits from Klass" do
      before() do
        Object.send(:remove_const, 'Child' ) if Object.const_defined?( 'Child' )
        class Child < Klass
        end
      end

      # sorry, Lamarckism not supported
      it "does NOT inherit it's parent class' Machines !!" do
        Child.state_fu_machine.should_not == Klass.state_fu_machine
      end

      it "should know the Machine after calling Klass.state_fu_machine.bind!( Child )" do
        Child.state_fu_machine.should_not == Klass.state_fu_machine
        Klass.state_fu_machine.bind!( Child )
        Klass.state_fu_machines.should == { StateFu::DEFAULT => Klass.state_fu_machine }
        Child.state_fu_machine.should == Klass.state_fu_machine
        Klass.state_fu_machine.bind!( Child, :snoo )
        Child.state_fu_machines.should == {
          StateFu::DEFAULT => Klass.state_fu_machine,
          :snoo            => Klass.state_fu_machine
        }
        Child.state_fu_machine(:snoo).should == Klass.state_fu_machine
      end

    end
  end
end
